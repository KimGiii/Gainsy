# HealthCare

운동·식단·신체변화를 하나로 기록하고 목표를 달성하는 iOS 헬스 트래킹 앱

## 기술 스택

**Backend**
- Java 21 + Spring Boot 3.3.4
- PostgreSQL 16 + Redis 7
- JWT (Access Token 24h / Refresh Token 30d)
- Flyway, Docker Compose

**iOS**
- Swift 6.0 + SwiftUI
- MVVM, strict concurrency (actor model)
- Keychain 토큰 저장
- iOS 16+

## 프로젝트 구조

```
health-care/
├── backend/          # Spring Boot API 서버
├── ios/              # SwiftUI 클라이언트
├── docs/             # 설계 문서 (PRD, API, DB 스키마)
└── research/         # 경쟁사 분석, 기술 벤치마크
```

## 주요 기능

### 운동 기록
- 운동 세션 기록 (근력, 유산소, 기타)
- 세션별 운동 종목 및 세트 추적
- 운동 카탈로그 110개 (근육군별 분류)
- AI 운동 추정 폴백 (검색 결과 없을 때)

### 식단 기록
- 식품 검색 및 기록
- 공공 데이터(식품디비) + 사용자 커스텀 식품
- **사용 횟수 기반 검색 정렬** (자주 쓰는 식품 우선)
- **누구나 직접 식품 등록 가능** (중복 자동 방지)
- AI 사진 분석 (OpenAI Vision)
- AI 텍스트 기반 영양 추정 폴백

### 신체 측정
- 체중, 체지방률, 근육량 등 5개 지표 추적
- 기간별 추세 그래프
- 진행 사진 업로드 및 비교

### 목표 & 인사이트
- 목표 설정 (체중, 운동, 근력 증가)
- 주간 회고 (목표별 진행률)
- 변화 분석 (기간별 통계)

## 문서

- [현재 상태](./docs/CURRENT_STATUS.md) — 구현 진행률, 최근 변경사항
- [아키텍처](./ARCHITECTURE.md)
- [API 설계](./docs/API_DESIGN.md)
- [DB 스키마](./docs/DB_SCHEMA.md)
- [PRD](./docs/design-docs/PRD.md)
