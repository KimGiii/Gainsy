# gainsy

> 운동·식단·신체변화를 하나로 기록하고 목표를 달성하는 iOS 헬스 트래킹 앱

[![Backend CI](https://github.com/KimGiii/Gainsy/actions/workflows/ci-backend.yml/badge.svg)](https://github.com/KimGiii/Gainsy/actions/workflows/ci-backend.yml)
[![iOS CI](https://github.com/KimGiii/Gainsy/actions/workflows/ci-ios.yml/badge.svg)](https://github.com/KimGiii/Gainsy/actions/workflows/ci-ios.yml)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![Java](https://img.shields.io/badge/Java-21-blue)
![iOS](https://img.shields.io/badge/iOS-16%2B-lightgrey)

---

## 스크린샷

| 홈 대시보드 | 운동 기록 | 식단 기록 | 신체 측정 | 목표 |
|:-----------:|:---------:|:---------:|:---------:|:----:|
| ![home](docs/screenshots/home.png) | ![exercise](docs/screenshots/exercise.png) | ![diet](docs/screenshots/diet.png) | ![progress](docs/screenshots/progress.png) | ![goals](docs/screenshots/goals.png) |

| 기록 메인 | 식단 기록 상세 | 변화 분석 | 주간 회고 |
|:---------:|:--------------:|:---------:|:---------:|
| ![기록메인](docs/screenshots/기록메인페이지.png) | ![식단기록](docs/screenshots/식단기록페이지.png) | ![변화분석](docs/screenshots/변화분석페이지.png) | ![주간회고](docs/screenshots/주간회고페이지.png) |

---

## 주요 기능

**운동 기록**
- 근력·유산소·기타 세션 기록, 종목별 세트/횟수/무게 추적
- 운동 카탈로그 110개 (근육군별 분류), AI 폴백 검색

**식단 기록**
- 식품 검색 및 기록 (공공 식품 DB + 사용자 커스텀 식품)
- 사용 빈도 기반 검색 정렬 — 자주 쓰는 식품 우선 노출
- AI 사진 분석 (OpenAI Vision) 및 텍스트 기반 영양 추정

**신체 측정 & 진행 사진**
- 체중·체지방률·근육량 등 5개 지표 기간별 추세 그래프
- S3 기반 진행 사진 업로드 및 날짜별 비교

**목표 & 주간 회고**
- 체중·운동·근력 목표 설정 및 달성률 추적
- 주간 회고 — 기간별 통계 및 변화 분석

**접근성 & UX**
- 다크 모드 완전 지원 (Forest 톤 어댑티브 컬러)
- Dynamic Type, VoiceOver 지원
- Pull-to-refresh, 세션 만료 자동 로그아웃

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| **iOS** | Swift 6.0, SwiftUI, MVVM, strict concurrency (actor model) |
| **Backend** | Spring Boot 3.3.4, Java 21 (Virtual Threads), JPA/Hibernate, Flyway |
| **DB / Cache** | PostgreSQL 16, Redis 7 |
| **인증** | JWT — Access Token 24h / Refresh Token 30d, Keychain |
| **스토리지** | AWS S3 (Presigned URL, 15분 TTL) |
| **푸시 알림** | Firebase FCM |
| **AI** | OpenAI GPT-4.1-mini (식단 사진 분석, 영양 추정) |
| **인프라** | AWS (EC2 t3.small / RDS PostgreSQL / ElastiCache Redis / S3 / ECR) |
| **IaC** | Terraform, Nginx 리버스 프록시, Let's Encrypt SSL |
| **CI/CD** | GitHub Actions |
| **로컬 개발** | Docker Compose (PostgreSQL + Redis + LocalStack S3) |

---

## 아키텍처

```
┌─────────────────────────────────────────────┐
│                 iOS (SwiftUI)               │
│  Features → ViewModel → APIClient (JWT)     │
└─────────────────┬───────────────────────────┘
                  │ HTTPS (api.gainsy.site)
┌─────────────────▼───────────────────────────┐
│           Spring Boot API Server            │
│  Controller → Service → Repository (JPA)    │
│  ├── PostgreSQL 16  (영속 데이터)            │
│  ├── Redis 7        (토큰 블랙리스트/캐시)   │
│  └── S3             (사진 스토리지)          │
└─────────────────────────────────────────────┘
```

상세 아키텍처는 [ARCHITECTURE.md](./ARCHITECTURE.md)를 참고하세요.

---

## 시작하기

### 사전 요구사항

- Java 21
- Docker Desktop
- Xcode 15+ (iOS 16 시뮬레이터)
- (선택) AWS CLI, Terraform — 프로덕션 인프라 배포 시 필요

### 로컬 실행

```bash
# 1. 저장소 클론
git clone https://github.com/KimGiii/Gainsy.git
cd health-care

# 2. 인프라 서비스 시작 (PostgreSQL 5433 / Redis 6379 / LocalStack 4566)
cd backend
docker compose up -d

# 3. 백엔드 실행
./gradlew bootRun

# 4. iOS — Xcode에서 ios/HealthCare.xcodeproj 열기 후 시뮬레이터 실행
```

### 환경 변수

백엔드는 기본값이 설정되어 있어 로컬에서는 별도 설정 없이 실행 가능합니다.  
프로덕션 배포 시 아래 환경 변수가 필요합니다.

| 변수 | 설명 |
|------|------|
| `JWT_SECRET` | JWT 서명 키 (32자 이상) |
| `POSTGRES_HOST` / `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` | 데이터베이스 접속 정보 |
| `REDIS_HOST` / `REDIS_PORT` | Redis 접속 정보 |
| `S3_BUCKET` / `S3_REGION` / `S3_ENDPOINT` | S3 스토리지 설정 |
| `OPENAI_API_KEY` | 식단 AI 분석용 OpenAI 키 |
| `PUBLIC_FOOD_API_KEY` | 공공 식품 영양 데이터 API 키 |

---

## 테스트

```bash
# 백엔드 전체 테스트
cd backend && ./gradlew test

# 백엔드 빌드
cd backend && ./gradlew build
```

iOS 테스트는 Xcode → **Product → Test** (⌘U)로 실행합니다.

---

## 배포

### CI/CD

| 워크플로우 | 트리거 | 동작 |
|-----------|--------|------|
| `ci-backend.yml` | `main`, `dev`, `prod` push | 빌드 + 테스트 |
| `ci-ios.yml` | `main`, `dev` push | 빌드 + 테스트 |
| `dev-to-prod.yml` | `dev → prod` PR merge | 프로덕션 배포 |

### 인프라

Terraform으로 AWS 인프라를 프로비저닝합니다.

```bash
cd infra
terraform init
terraform apply
```

- **도메인**: `api.gainsy.site` (Route 53 + Let's Encrypt, 자동 갱신)
- **리전**: ap-northeast-2 (서울)

---

## 프로젝트 구조

```
health-care/
├── backend/
│   └── src/main/java/com/healthcare/
│       ├── common/          # 예외, 응답 래퍼, 보안, JWT 필터
│       └── domain/
│           ├── auth/        # 로그인, 회원가입, 토큰 갱신
│           ├── user/        # 사용자 프로필
│           ├── exercise/    # 운동 세션, 세트, 카탈로그
│           ├── diet/        # 식단, 식품, AI 분석
│           ├── bodymeasurement/  # 신체 지표, 진행 사진
│           ├── goals/       # 목표 설정 및 추적
│           └── insights/    # 주간 회고, 통계
├── ios/HealthCare/
│   ├── Core/               # 네트워크(APIClient), 인증(AuthState), 저장소
│   ├── DesignSystem/       # 어댑티브 컬러 토큰, 공통 컴포넌트
│   ├── Features/           # Auth / Home / Exercise / Diet / Progress / Goals / Profile
│   └── Navigation/         # 탭 네비게이션
├── infra/                  # Terraform (VPC, EC2, RDS, ElastiCache, S3, ECR)
├── docs/                   # PRD, API 설계, DB 스키마, 현재 상태
├── .github/workflows/      # CI/CD 파이프라인
└── ARCHITECTURE.md
```

---

## 문서

| 문서 | 내용 |
|------|------|
| [현재 상태](./docs/CURRENT_STATUS.md) | 구현 진행률, 최근 변경사항 |
| [아키텍처](./ARCHITECTURE.md) | 시스템 설계, 기술 결정 이유 |
| [API 설계](./docs/design-docs/API_DESIGN.md) | REST 엔드포인트 명세 |
| [DB 스키마](./docs/design-docs/DB_SCHEMA.md) | PostgreSQL 테이블 설계 |
| [PRD](./docs/design-docs/PRD.md) | 제품 요구사항 |
| [화면 구조](./docs/design-docs/MVP_SCREEN_STRUCTURE.md) | 네비게이션 및 화면 흐름 |
