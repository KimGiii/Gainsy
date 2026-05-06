# GitHub Actions 시크릿 설정 가이드

## 공통 시크릿 (Repository Secrets)

| 시크릿 | 설명 |
|--------|------|
| `AWS_ACCESS_KEY_ID` | ECR push 권한을 가진 IAM 사용자 키 |
| `AWS_SECRET_ACCESS_KEY` | 위 IAM 사용자의 시크릿 키 |

## Dev 환경 (Environment: `dev`)

GitHub → Settings → Environments → `dev` 에서 설정

| 시크릿 | 예시 |
|--------|------|
| `DEV_SSH_HOST` | `dev.healthcare.app` 또는 IP |
| `DEV_SSH_USER` | `ubuntu` |
| `DEV_SSH_KEY` | EC2 .pem 키 내용 전체 |
| `DEV_DB_URL` | `jdbc:postgresql://host:5432/healthcare_dev` |
| `DEV_DB_USERNAME` | `healthcare` |
| `DEV_DB_PASSWORD` | 안전한 비밀번호 |
| `DEV_REDIS_HOST` | Redis 호스트 |
| `DEV_JWT_SECRET` | 32자 이상 랜덤 문자열 |
| `DEV_S3_ENDPOINT` | 비워두면 AWS S3 직접 사용 |
| `DEV_OPENAI_API_KEY` | OpenAI API 키 (없으면 AI 기능 비활성화) |
| `DEV_PUBLIC_FOOD_API_KEY` | 공공데이터포털 API 키 |

## Prod 환경 (Environment: `prod`)

GitHub → Settings → Environments → `prod` 에서 설정  
**Required reviewers 설정으로 수동 승인 추가 권장**

| 시크릿 | 예시 |
|--------|------|
| `PROD_SSH_HOST` | `api.healthcare.app` 또는 IP |
| `PROD_SSH_USER` | `ubuntu` |
| `PROD_SSH_KEY` | EC2 .pem 키 내용 전체 |
| `PROD_DB_URL` | `jdbc:postgresql://host:5432/healthcare_prod` |
| `PROD_DB_USERNAME` | `healthcare` |
| `PROD_DB_PASSWORD` | 안전한 비밀번호 |
| `PROD_REDIS_HOST` | Redis 호스트 |
| `PROD_JWT_SECRET` | 32자 이상 랜덤 문자열 (dev와 다르게) |
| `PROD_DOMAIN` | `api.healthcare.app` (헬스체크용) |
| `PROD_OPENAI_API_KEY` | OpenAI API 키 |
| `PROD_PUBLIC_FOOD_API_KEY` | 공공데이터포털 API 키 |

## ECR 리포지토리 생성

```bash
aws ecr create-repository \
  --repository-name healthcare-api \
  --region ap-northeast-2
```

## EC2 서버 사전 준비

각 서버에 Docker, AWS CLI, nginx 설치 필요:

```bash
# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker ubuntu

# AWS CLI
sudo snap install aws-cli --classic

# nginx (prod 블루그린 배포용)
sudo apt install -y nginx
```

FCM 서비스 계정 JSON을 `/etc/healthcare/fcm-credentials.json`에 배치
