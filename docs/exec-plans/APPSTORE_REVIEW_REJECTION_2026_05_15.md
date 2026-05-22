# App Store 심사 거절 대응 — Guideline 2.1(a)

> Submission ID: a5176114-63d2-4799-b5aa-dc8a716bd4d9
> Review date: 2026-05-15
> Review devices: iPhone 17 Pro Max (iOS 26.5), iPad Air 11-inch M3 (iPadOS 26.5)
> Version reviewed: 1.0 (4)
> 대응 완료일: 2026-05-18

## 1. 거절 개요

### 1.1. 적용 가이드라인

Guideline 2.1(a) — Performance, App Completeness.

### 1.2. Apple이 보고한 증상

> The app exhibited one or more bugs that would negatively impact users.
> Bug description: **Error for registration and login.**

심사 환경은 인터넷 연결이 활성화된 iPhone 17 Pro Max·iPad Air M3, iOS·iPadOS 26.5.

### 1.3. 1차 가설 후보

조사 진행 전 검토한 후보 원인:

1. 빌드에 박힌 API base URL이 운영 도메인이 아님(localhost 등 잔재).
2. ATS(App Transport Security) 설정 누락.
3. 운영 서버 SSL 인증서 만료·체인 깨짐.
4. iOS 26.5에서 동작 안 하는 deprecated API 사용.
5. 약관 동의 등 필수 필드 누락으로 백엔드 4xx.
6. 백엔드 응답 래퍼와 iOS 디코딩 미스매치.
7. 운영 서버 자체 다운.

## 2. 조사 결과

### 2.1. iOS·백엔드 코드는 정상

다음을 검증해 모두 정합함을 확인.

- 백엔드 응답 래퍼 [ApiResponse.java](../../backend/src/main/java/com/healthcare/common/response/ApiResponse.java)
  의 `{success, message, data}` 구조와 iOS [APIClient.swift](../../ios/HealthCare/Core/Network/APIClient.swift)
  의 `SuccessEnvelope<T>` 디코딩이 일치.
- camelCase 직렬화·필드명·Jackson 기본 naming strategy 모두 정상.
- iOS [TokenResponse](../../ios/HealthCare/Features/Auth/Models/LoginRequest.swift)
  의 `accessToken / refreshToken / expiresIn / onboardingCompleted` 가 백엔드 응답과 정확히 매칭.
- xcconfig `BASE_URL`이 `https://api.gainsy.site` 로 정상 설정([Release.xcconfig](../../ios/Configs/Release.xcconfig)).
- ATS: 명시적 예외 없이 HTTPS 강제(시스템 기본값).
- 회원가입 필수 동의 체크박스(약관·개인정보)가 활성화 조건에 포함됨([SignUpView.swift](../../ios/HealthCare/Features/Auth/Views/SignUpView.swift)).
- 운영 SSL 인증서: Let's Encrypt, `notBefore=2026-05-15 14:17 GMT`, `notAfter=2026-08-13`. 유효.

### 2.2. 실제 원인 — 운영 백엔드 502 Bad Gateway

심사 직후·대응 시점까지 운영 도메인에서 다음 결과:

```text
GET  https://api.gainsy.site/actuator/health         → 502
POST https://api.gainsy.site/api/v1/auth/register    → 502
POST https://api.gainsy.site/api/v1/auth/login       → 502
```

Nginx 응답(HTTP→HTTPS 301)·TLS 핸드셰이크는 정상. **Nginx 뒤의 Spring Boot 컨테이너가 응답하지 않아** upstream 호출이 실패해 502를 반환.

### 2.3. 사실상의 수명 — 한 번 죽으면 영구 502가 되는 구조

명시적 자동 종료 설정(Spot 인스턴스·EventBridge cron·systemd `RuntimeMaxSec`·CloudWatch `alarm_actions`·GitHub Actions 스케줄) 은 모두 **없음**.

그러나 다음 3가지가 결합해 한 번 죽으면 자동 회복이 불가능한 상태였음.

#### 2.3.1. Docker `--restart` 정책 부재

[.github/workflows/dev-to-prod.yml](../../.github/workflows/dev-to-prod.yml) 의 `docker run` 에 `--restart` 옵션이 없어 Docker의 기본값 `no`가 적용. 컨테이너가 비정상 종료되거나 EC2가 재부팅되면 자동 재기동되지 않음.

#### 2.3.2. 컨테이너 메모리 한계 미지정

`docker run` 에 `--memory` 옵션이 없어 컨테이너가 호스트 메모리(t3.small 2GB) 전체를 점유할 수 있음. JVM이 호스트 전체의 75%를 점유하다가 호스트 OOM-killer에 잡히기 쉬움.

#### 2.3.3. JVM이 OOM에 우아하게 종료 못함

[backend/Dockerfile](../../backend/Dockerfile) 에 `-XX:+ExitOnOutOfMemoryError` 가 없어, OOM 발생 시 JVM이 종료되는 대신 **GC 스래싱으로 "살아있는데 응답 불가"** 상태에 빠짐. Nginx는 upstream 연결은 되지만 응답 타임아웃으로 502를 반환.

## 3. 적용된 조치 (prod 8d48f04)

### 3.1. Docker 컨테이너 자동 재기동 + 메모리 한계

[.github/workflows/dev-to-prod.yml](../../.github/workflows/dev-to-prod.yml) 의 `docker run` 에 3개 옵션 추가.

```bash
docker run -d \
  --name $GREEN_NAME \
  --restart unless-stopped \
  --memory 1400m \
  --memory-swap 1400m \
  -p ${GREEN_PORT}:8080 \
  ...
```

- `--restart unless-stopped`: 컨테이너 비정상 종료·EC2 재부팅 시 Docker 데몬이 자동 재기동.
- `--memory 1400m`: t3.small RAM 2GB의 ~70%. 호스트 OS·Nginx·CloudWatch agent 몫(~600MB) 남김. 컨테이너 단위 OOM-killer가 호스트보다 먼저 동작.

### 3.2. JVM OOM 즉시 종료 + Heap dump

[backend/Dockerfile](../../backend/Dockerfile) 에 3개 옵션 추가.

```dockerfile
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-XX:+ExitOnOutOfMemoryError", \
  "-XX:+HeapDumpOnOutOfMemoryError", \
  "-XX:HeapDumpPath=/tmp/heapdump.hprof", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
```

- OOM 시 GC 스래싱 대신 즉시 종료 → 3.1 의 `--restart` 가 새 컨테이너 기동.
- Heap dump 로 사후 원인 분석 가능.

### 3.3. 배포 후 외부 검증 게이트 추가

[.github/workflows/dev-to-prod.yml](../../.github/workflows/dev-to-prod.yml) 의 마지막 단계를 EC2 내부 localhost 호출에서 외부 도메인 호출로 교체. health 체크 + 회원가입/로그인 smoke test 통과 시에만 워크플로우 성공.

```yaml
- name: Verify external health endpoint
  run: |
    for i in $(seq 1 12); do
      STATUS=$(curl -4 -sS -o /dev/null -w "%{http_code}" --max-time 10 \
        https://api.gainsy.site/actuator/health || true)
      ...
    done

- name: Smoke test register & login
  run: |
    EMAIL="ci_smoke_$(date +%s)@example.com"
    REG=$(curl -4 ... -X POST .../auth/register ...)
    [ "$REG" = "201" ] || exit 1
    LOG=$(curl -4 ... -X POST .../auth/login ...)
    [ "$LOG" = "200" ] || exit 1
```

다음에 같은 사고가 재발해도 워크플로우 빨간불로 즉시 인지 가능.

## 4. 검증 결과

### 4.1. Before / After

| 엔드포인트 | 거절 시점 (5/15) | 대응 시작 (5/18 06:00) | **대응 후 (5/18 06:18)** |
|---|---|---|---|
| `/actuator/health` | 502 | 502 | **200 `{"status":"UP"}`** |
| `POST /api/v1/auth/register` | 502 | 502 | **201 + accessToken** |
| `POST /api/v1/auth/login` | 502 | 502 | **200 + accessToken** |

### 4.2. 응답 본문 정합성

회원가입 응답 예시:

```json
{
  "success": true,
  "data": {
    "userId": 5,
    "email": "verify_...@example.com",
    "displayName": "Verifier",
    "accessToken": "eyJhbGciOiJIUzUxMiJ9...",
    "refreshToken": "eyJhbGciOiJIUzUxMiJ9...",
    "expiresIn": 86400,
    "onboardingCompleted": false
  }
}
```

iOS `SuccessEnvelope<TokenResponse>` 디코딩과 완벽 일치.

### 4.3. GitHub Actions 워크플로우

[Run #26016771998](https://github.com/KimGiii/health-care/actions/runs/26016771998) — 모든 단계 통과:

- Build & push Docker image
- Deploy to Prod EC2 (blue-green swap)
- Verify external health endpoint (외부 200)
- Smoke test register & login (201 / 200)

## 5. 남은 작업

### 5.1. iOS 실기기 smoke test (재제출 전 필수)

iOS 26.x 실기기에서:

1. Xcode Release scheme 빌드 ([Release.xcconfig](../../ios/Configs/Release.xcconfig) 의 `BASE_URL` = `https://api.gainsy.site` 확인).
2. 앱 신규 설치 → 회원가입(약관 2개 동의) → 토큰 저장 확인.
3. 앱 강제종료 → 재실행 → 자동 로그인(Keychain 토큰 재사용) 확인.
4. 로그아웃 → 로그인 다시.
5. 비행기 모드 토글로 네트워크 에러 메시지 노출 확인.
6. iPad Air M3에서도 동일 흐름 1회.

### 5.2. App Store Connect 재제출

- Resolution Center 에서 같은 빌드 재심사 요청 또는 1.0(5) 신규 업로드.
- Reviewer Notes:
  > Resolved a backend availability incident that prevented registration and login at the time of submission. End-to-end verified on iOS 26.5 device and via external smoke tests in CI.
- 데모 계정 등록 여부 확인.

### 5.3. dev 브랜치 동기화 (선택)

prod 가 dev 보다 1커밋(8d48f04) 앞서 있어 다음 PR 에서 충돌 가능.

```bash
git checkout dev
git merge origin/prod --ff-only
git push origin dev
```

## 6. 재발 방지 — Follow-up 권장 (별도 PR)

### 6.1. EC2 재프로비저닝 시 백엔드 자동 기동 보장

`--restart unless-stopped` 가 EC2 reboot 시 자동 기동은 처리하지만, 컨테이너가 한 번도 존재하지 않은 깨끗한 EC2(재프로비저닝 직후) 에서는 동작하지 않음. [user_data.sh](../../infra/terraform/aws/templates/user_data.sh) 에 마지막 배포 이미지(`prod-latest`)를 ECR 에서 pull 해 자동 기동하는 systemd unit 추가.

환경변수를 `/etc/healthcare/backend.env` 로 분리하는 구조 변경 필요. 별도 PR 권장.

### 6.2. Let's Encrypt 영속화

EC2 EBS 가 휘발성이라 재프로비저닝 시 인증서 소실 가능. `/etc/letsencrypt` 를 별도 EBS 볼륨 또는 S3 백업으로 분리하고 부팅 시 자동 복원.

### 6.3. Route 53 AAAA 레코드 + Nginx IPv6 리스닝

현재 [dns.tf](../../infra/terraform/aws/dns.tf) 에는 A 레코드만 있음. Apple의 IPv6-only 테스트 환경 대비로 AAAA 레코드와 `listen [::]:443 ssl;` 추가. (NAT64 환경에서도 동작하지만 직접 지원이 더 안전.)

### 6.4. iOS Release 빌드 CI smoke

TestFlight 업로드 전 GitHub Actions 에서 `curl` 기반 prod health/register 더미 호출 통과 필수로. 본 사고처럼 빌드는 멀쩡한데 서버가 죽어 있는 상황을 사전 차단.

## 7. 핵심 파일 참조

### 7.1. 수정된 파일

- [.github/workflows/dev-to-prod.yml](../../.github/workflows/dev-to-prod.yml) — 3.1, 3.3
- [backend/Dockerfile](../../backend/Dockerfile) — 3.2

### 7.2. 검증 참조 파일

- [backend/src/main/java/com/healthcare/common/response/ApiResponse.java](../../backend/src/main/java/com/healthcare/common/response/ApiResponse.java)
- [backend/src/main/java/com/healthcare/domain/auth/controller/AuthController.java](../../backend/src/main/java/com/healthcare/domain/auth/controller/AuthController.java)
- [backend/src/main/resources/application-prod.yml](../../backend/src/main/resources/application-prod.yml)
- [ios/HealthCare/Core/Network/APIClient.swift](../../ios/HealthCare/Core/Network/APIClient.swift)
- [ios/HealthCare/Features/Auth/Views/SignUpView.swift](../../ios/HealthCare/Features/Auth/Views/SignUpView.swift)
- [ios/Configs/Release.xcconfig](../../ios/Configs/Release.xcconfig)
- [infra/terraform/aws/compute.tf](../../infra/terraform/aws/compute.tf)
- [infra/terraform/aws/templates/user_data.sh](../../infra/terraform/aws/templates/user_data.sh)
- [docs/CURRENT_STATUS.md](../CURRENT_STATUS.md)
- [docs/exec-plans/APPSTORE_RELEASE_CHECKLIST.md](APPSTORE_RELEASE_CHECKLIST.md)
