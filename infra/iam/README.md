# IAM 정책

## 파일 구성

| 파일 | 용도 | 부여 대상 |
|------|------|----------|
| `terraform-deploy-policy.json` | Terraform `plan` / `apply` 전체 권한 | 개발자 IAM 사용자 |
| `github-actions-policy.json` | ECR 이미지 push 전용 (최소 권한) | GitHub Actions IAM 사용자 |

---

## 적용 방법

### 1. Terraform 배포용 정책

```bash
# 정책 생성
aws iam create-policy \
  --policy-name HealthcareTerraformDeploy \
  --policy-document file://infra/iam/terraform-deploy-policy.json

# IAM 사용자에 연결
aws iam attach-user-policy \
  --user-name YOUR_IAM_USER \
  --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/HealthcareTerraformDeploy
```

### 2. GitHub Actions 배포용 정책

```bash
# 전용 IAM 사용자 생성
aws iam create-user --user-name healthcare-github-actions

# 정책 생성 및 연결
aws iam create-policy \
  --policy-name HealthcareGithubActions \
  --policy-document file://infra/iam/github-actions-policy.json

aws iam attach-user-policy \
  --user-name healthcare-github-actions \
  --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/HealthcareGithubActions

# 액세스 키 발급 → GitHub Secrets 등록
aws iam create-access-key --user-name healthcare-github-actions
```

발급된 `AccessKeyId` → `AWS_ACCESS_KEY_ID`  
발급된 `SecretAccessKey` → `AWS_SECRET_ACCESS_KEY`

---

## 권한 분리 원칙

```
개발자 (Terraform 운영자)
└── HealthcareTerraformDeploy
    ├── VPC / 서브넷 / 보안그룹
    ├── EC2 / EIP / 키페어
    ├── RDS / ElastiCache
    ├── ECR 리포지토리 관리
    ├── S3 버킷 관리
    ├── IAM 역할·정책 (EC2 인스턴스 역할 한정)
    ├── CloudWatch 알람·로그
    └── Terraform 원격 상태 (S3 + DynamoDB)

GitHub Actions
└── HealthcareGithubActions
    ├── ecr:GetAuthorizationToken  (전체 리소스)
    └── ECR push/pull              (healthcare-api 리포지토리만)
```
