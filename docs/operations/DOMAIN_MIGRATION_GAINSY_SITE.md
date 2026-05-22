# 도메인 전환 가이드 — api.gainsy.site (HTTPS)

운영자가 직접 수행해야 할 수동 절차를 순서대로 정리한다. 코드/IaC 변경은
이미 커밋되어 있다.

## 사전 조건

- `gainsy.site` 도메인 보유 (등록처 콘솔 접근 권한)
- AWS Terraform 실행 권한 (`infra/terraform/aws`)
- 운영 EC2 SSH 접근 권한
- 운영자 이메일 (Let's Encrypt 만료 알림 수신용)

## 변경된 파일 (참고)

- `infra/terraform/aws/dns.tf` (신규) — Route 53 호스팅 영역 + A 레코드
- `infra/terraform/aws/variables.tf` — `root_domain` 변수 추가
- `infra/terraform/aws/terraform.tfvars` — `root_domain = "gainsy.site"`
- `infra/terraform/aws/outputs.tf` — `route53_nameservers`, `api_fqdn` 출력 추가
- `infra/terraform/aws/compute.tf` — user_data에 `api_domain` 전달
- `infra/terraform/aws/templates/user_data.sh` — Nginx `server_name` + ACME challenge 경로
- `backend/src/main/resources/application-prod.yml` — `server.forward-headers-strategy: native`
- `ios/Configs/{Debug,Staging,Release}.xcconfig` — `https://api.gainsy.site`
- `ios/project.yml` — `NSExceptionDomains` 블록 제거, scheme env BASE_URL HTTPS

---

## 1. Route 53 호스팅 영역 생성

```bash
cd infra/terraform/aws
terraform init      # backend가 변경됐다면
terraform plan
terraform apply
```

apply 후 네임서버 4개를 확인한다.

```bash
terraform output route53_nameservers
```

예시:
```
[
  "ns-123.awsdns-12.com",
  "ns-456.awsdns-45.org",
  "ns-789.awsdns-78.net",
  "ns-2000.awsdns-99.co.uk",
]
```

## 2. 도메인 등록처에서 네임서버 변경

도메인 등록처(가비아/후이즈/Namecheap 등) 콘솔 → `gainsy.site` 관리 →
**네임서버 변경** → 위 4개 NS 입력.

- DNS 전파: 보통 1~6시간, 최대 48시간
- 전파 확인:
  ```bash
  dig +short NS gainsy.site
  dig +short A  api.gainsy.site
  ```
  A 레코드가 EC2 EIP(`terraform output app_public_ip`)와 일치하면 성공

## 3. EC2에서 Certbot으로 SSL 인증서 발급

DNS 전파 확인 후 EC2에 SSH 접속.

```bash
ssh -i healthcare-prod-key.pem ubuntu@<EIP>

# Nginx 설정의 server_name이 api.gainsy.site인지 확인
sudo grep server_name /etc/nginx/sites-available/healthcare
# (현재 EC2는 user_data 변경 전에 부팅됐다면 _이 그대로일 수 있음)
# 그 경우 다음 sed 한 줄로 교체:
sudo sed -i 's/server_name _;/server_name api.gainsy.site _;/' /etc/nginx/sites-available/healthcare
sudo nginx -t && sudo systemctl reload nginx

# Let's Encrypt 인증서 발급 + Nginx 자동 설정
sudo certbot --nginx \
  -d api.gainsy.site \
  --non-interactive \
  --agree-tos \
  -m <admin-email>

# 자동 갱신 타이머 확인
sudo systemctl status certbot.timer
```

성공하면 Certbot이 자동으로 443 server 블록을 추가하고 80→443 리다이렉트를
설정한다.

## 4. 동작 검증

```bash
# 외부에서
curl -I https://api.gainsy.site/actuator/health
# → HTTP/2 200, content-type: application/json
# → 인증서: Let's Encrypt (Subject: api.gainsy.site)

# HTTP → HTTPS 리다이렉트
curl -I http://api.gainsy.site/actuator/health
# → 301 Location: https://api.gainsy.site/...
```

## 5. GitHub Actions 시크릿 업데이트

`PROD_S3_PUBLIC_ENDPOINT`가 기존 IP 기반이면 새 도메인으로 변경:

- 기존: `http://13.209.216.146/s3`
- 신규: `https://api.gainsy.site/s3`

GitHub → Repo → Settings → Environments → `prod` → `PROD_S3_PUBLIC_ENDPOINT`
값을 수정한 뒤, 다음 deploy-prod 실행 시 자동 반영된다.

> Pre-signed URL이 새 도메인으로 발급되므로 기존에 발급된 URL은 만료 전까지
> 그대로 동작한다. 새 업로드부터 HTTPS URL이 적용된다.

## 6. iOS 빌드 재생성

xcconfig가 변경됐으므로 xcodegen으로 프로젝트를 재생성한다.

```bash
cd ios
xcodegen generate
open HealthCare.xcodeproj
```

Xcode에서 Release 스킴으로 빌드 → BASE_URL이 `https://api.gainsy.site`인지
런타임에서 확인 (`APIClient` 로그 또는 네트워크 인스펙터).

## 7. 롤백 절차

문제 발생 시:

1. iOS — xcconfig를 이전 `http://13.209.216.146`로 복구, `NSExceptionDomains`
   블록도 project.yml에 복구. 단, 이미 빌드된 IPA는 그대로 사용 가능 (앱은 변경 없음).
2. 백엔드/Nginx — Certbot이 추가한 443 블록만 비활성화하면 80번만 동작:
   ```bash
   sudo sed -i.bak '/listen 443/,/^}/d' /etc/nginx/sites-available/healthcare
   sudo nginx -t && sudo systemctl reload nginx
   ```
3. DNS — Route 53 호스팅 영역은 유지하고, 등록처 NS만 원복하면 도메인 자체가
   비활성화된다 (앱은 여전히 IP로 동작).

## 후속 작업 (별도)

- [ ] App Store Connect에서 개인정보 처리방침/이용약관 URL 등록
- [ ] 백엔드 CORS 정책 — 향후 웹 페이지가 생기면 `https://gainsy.site` 화이트리스트
- [ ] Cloudflare 또는 ALB 전환 (트래픽 증가 시)
- [ ] `api.gainsy.site`용 CloudWatch 알람 (TLS 만료 D-30, 5xx 비율)
