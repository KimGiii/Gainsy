# Changelog

모든 notable 변경사항은 이 파일에 기록됩니다.

## [Unreleased]

### Added (2026-05-23)

#### 백엔드 — 영양소 표준 10종 통일 ([PR #30](https://github.com/KimGiii/Gainsy/pull/30))

- **V16 마이그레이션** — `food_catalog` / `food_entries` / `diet_logs` / `meal_photo_analysis_items` 4개 테이블에 신규 6컬럼 추가 (당류·식이섬유·포화지방·트랜스지방·콜레스테롤·나트륨). 식약처 영양표시기준 10종을 외부 공공 API → FoodCatalog → FoodEntry → DietLog → AI 추정 응답까지 일관 적용.
- **공공 API 매핑 확장** — `PublicFoodApiClientImpl.PublicFoodItem` + `toExternalResult()`에 `sugar`·`fibtg`·`fasat`·`fatrn`·`chole`·`nat` 매핑. 그동안 식약처 API가 반환하던 6필드가 추출 단계에서 버려지던 문제 해결.
- **DietLogService 합산 로직 재작성** — `buildEntries()` 헬퍼 + `Aggregation` record. 신규 record `DietLogNutritionTotals`로 `DietLog.update()` 시그니처 단순화. `createDietLog` / `updateDietLog` 모두 10영양소 환산·합산.
- **AI 텍스트 추정 응답 envelope** — `AiNutritionEstimateResponse`를 record(`isFood` / `items[]` / `totalNutrition` / `error` / `disclaimer` / `aiEstimated`)로 재구성. 신규 `NutritionFacts` / `ServingBasis`(PER_ITEM·PER_100G·CUSTOM_WEIGHT) / `EstimatedItem` / `EstimationError`.
- **AI 추정 프롬프트·파싱 재작성** — `AiNutritionEstimationService`에 servingBasis 판단 규칙(브랜드/포장식품→PER_ITEM, 일반 식재료→PER_100G, 무게 명시→CUSTOM_WEIGHT), 다중 음식 items 분리, isFood=false 분기, confidence high/medium/low → 0.9/0.6/0.3 정규화. 마크다운 펜스 제거 + `totalNutrition` 누락 시 items 합산 폴백.
- **테스트 14 케이스** — `AiNutritionEstimationServiceTest`에 PER_100G·PER_ITEM·CUSTOM_WEIGHT·multi-item·isFood=false·AI_UNAVAILABLE·unknown enum 폴백·마크다운 펜스 케이스.

#### 백엔드 — 사진 분석 프리미엄 게이팅 ([PR #30](https://github.com/KimGiii/Gainsy/pull/30))

- **V17 마이그레이션** — `users.is_premium BOOLEAN NOT NULL DEFAULT FALSE` + `WHERE is_premium = TRUE` 부분 인덱스.
- **`PremiumRequiredException` + 403 PREMIUM_REQUIRED 핸들러** — `GlobalExceptionHandler`에 매핑.
- **`PremiumAccessGuard` 컴포넌트** — `assertPremium(userId)` 재사용.
- **`MealPhotoAnalysisController` 4개 엔드포인트 게이팅** — initiate / analyze / get / confirm.
- 테스트 계정 활성화: `UPDATE users SET is_premium = TRUE WHERE email = '...'`.

#### iOS — 백엔드 정합 + 영양소 envelope + 프리미엄 UI ([PR #31](https://github.com/KimGiii/Gainsy/pull/31))

- **`AuthState.isPremium` 캐싱** + `updatePremiumStatus(_:)`. `MyPageViewModel.load(apiClient:authState:)`가 `/me` 응답으로 동기화.
- **`APIError.premiumRequired`** — `APIClient`가 `403 + code="PREMIUM_REQUIRED"` 응답을 `.unauthorized`와 분리해 별도 매핑(자동 로그아웃 트리거 방지).
- **`UserProfile.isPremium`** Optional 추가.
- **`AddDietLogViewModel`** — `estimateWithAI` envelope 대응(isFood=false / AI_UNAVAILABLE 분기), `addAiEstimatedFood`가 첫 item을 10영양소 카탈로그로 저장 + draft 추가 + **검색 시트 자동 닫힘**, `startPhotoAnalysis`에서 `APIError.premiumRequired` 잡아 `showPremiumPaywall` 트리거.
- **`AddDietLogView`** — 사진 버튼을 `photoButton` 조건부 뷰로 추출(프리미엄 → `PhotosPicker`, 비프리미엄 → 자물쇠 + PRO 배지 → paywall). AI 추정 카드를 envelope 구조로 재작성(servingBasis·estimatedWeight·8개 영양소 표시·multi-item 안내·estimationNote·신뢰도 라벨).
- **`PremiumPaywallSheet` 신규** — PRO 안내 + 기능 리스트 + "구독 결제 준비 중" 메시지.
- **DietModels.swift 6필드 확장** — `FoodEntryResponse` / `FoodCatalogItem`(amount 헬퍼 6종) / `DietLogDetailResponse` / `DietLogSummary` / `CreateDietLogResponse` / `ExternalFoodResult` / `ImportFoodRequest`. `DraftFoodEntry`에 10영양소 계산 helper + `EstimatedItem` init(servingBasis에 따라 per_100g 환산).
- **테스트 71개 그린** — `xcodebuild test -only-testing HealthCareTests`.

#### 부수 정리

- **`PRODUCT_MODULE_NAME = Gainsy`** — 메인 앱 타겟 Debug/Release/Staging 3개 빌드 컨피그에 추가. 앱 리브랜드 이후 깨져있던 `@testable import Gainsy` 테스트 빌드 복구. `PRODUCT_NAME`은 그대로 유지.

### Added (2026-05-20)

#### iOS

- **App Store 재심사 거절 3건 대응** ([PR #24](https://github.com/KimGiii/Gainsy/pull/24))
  - Guideline 2.5.1 — 미사용 HealthKit 권한 키 2개 제거 (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`)
  - Guideline 2.1 — `TrackingPermissionView` 신규: ATT 요청 전 사전 설명 화면, 스플래시 2.6초 후 노출, 시뮬레이터/UI 테스트 자동 스킵
  - Guideline 1.4.1 — `MedicalSourcesView` 신규: WHO·대한비만학회·식약처·USDA 출처 + 의료 면책 고지; `AddMeasurementView`, `BodyMeasurementView`, `DietLogDetailView`, `MyPageView` 4곳에 진입점 추가
  - `SignUpView`, `MyPageView` 법적 문서 URL → `kimgiii.github.io/Gainsy`로 수정

- **진행 사진 업로드 실패 fallback + 재시도 UX**
  - `ProgressPhotoViewModel` — 업로드 3단계별 실패 메시지 분리 (서버 연결 실패 / 사진 전송 실패 / 메타데이터 등록 실패)
  - `ProgressPhotoViewModel` — `uploadFailed`, `uploadFailureMessage`, `retryUpload()` 추가; 실패 시 알림 대신 인라인 배너로 전환
  - `AddProgressPhotoView` — 실패 시 삼각 경고 아이콘 + 단계별 안내 문구 배너 표시
  - `AddProgressPhotoView` — "저장하기" 버튼 → "↺ 다시 시도" 버튼으로 자동 전환; 새 사진 선택 시 실패 상태 초기화
  - JPEG 변환 실패(재시도 불가)는 기존 알림 유지

- **핵심 플로우 UI 테스트 추가** ([PR #25](https://github.com/KimGiii/Gainsy/pull/25))
  - `CoreFlowUITests.swift` — XCUITest 9개: 기록 허브 카드 표시, 운동·식단·신체 측정 진입 + Add 폼 시트 열기 + 저장 버튼 초기 비활성화 확인
  - 모든 테스트 `UI_TEST_AUTHENTICATED` 인수 사용 (실 API 미사용)

### Added (2026-05-04)

#### 백엔드
- **식품 카탈로그 사용 횟수 추적 (V13 마이그레이션)**
  - `food_catalog` 테이블에 `usage_count BIGINT NOT NULL DEFAULT 0` 컬럼 추가
  - 식단 기록 생성 시 사용된 식품 종류별(distinct) `usage_count` +1
  - 식단 기록 삭제 시 포함된 식품 종류별(distinct) `usage_count` -1 (0 미만 불가)
  - 검색 결과 정렬: 이름 접두사 매칭 우선 → `usage_count DESC` → 이름 가나다순

- **사용자 직접 식품 등록 (Custom Food)**
  - `POST /api/v1/diet/catalog` — 누구나 식품을 공용 DB에 직접 등록 가능
  - 같은 이름+카테고리 조합은 중복 등록 방지 (idempotent, DB 유니크 인덱스)
  - 입력 정규화: NFC normalize + 연속 공백 축약
  - Bean Validation: 이름 100자 이내, HTML 특수문자 차단, 칼로리 0~9999

- **식품 검색 공개화**
  - `GET /api/v1/diet/catalog` Authorization 헤더 required=false로 변경
  - 검색 API가 모든 커스텀 식품을 전체 사용자에게 공개

- **API 응답 강화**
  - `FoodCatalogResponse` — `usageCount`, `createdByUserId` 필드 추가

- **AI Nutrition 컨트롤러 안정성**
  - `AiNutritionController` — ObjectProvider 패턴으로 OPENAI_API_KEY 미설정 시 안전 처리

#### iOS
- **식품 직접 등록 UI (`AddCustomFoodView`)**
  - 검색 결과가 없을 때 "직접 등록하기" 버튼 노출
  - 식품명, 카테고리(Picker), 칼로리(필수), 단백질/탄수/지방 입력 폼
  - 검색어 자동 채움 (`.onAppear`)
  - 등록 성공 시 결과 목록 맨 위에 prepend + 자동 선택

- **검색 결과 중복 제거**
  - `catalogResults`, `externalResults` 모두 `displayName` 기준 `uniqued(by:)` 처리
  - `Array<T>.uniqued(by:)` 확장 메서드 추가 (`Date+Formatting.swift`)

- **탭 네비게이션 리셋**
  - 탭 전환 시 이전 탭의 NavigationStack을 루트로 리셋 (`MainTabView`)

- **APIEndpoint 확장**
  - `getExerciseCatalog` muscleGroup 파라미터 추가

- **모델 업데이트**
  - `FoodCatalogItem` — `usageCount`, `createdByUserId` 필드 추가
  - `AddDietLogViewModel` — `submitCustomFood()`, `showCustomFoodForm` 상태 추가

### Changed

- Phase 3 진행률: 97% → 100% (식품 직접 등록 완료)

### Fixed

- `FoodCatalogRepository` — 중복된 메서드 제거, 공개 검색(`searchAll()`) 안정화

## [v0.3.0] - 2026-04-28

### Added

#### 백엔드
- AI 영양 추정 서비스 (`AiNutritionEstimationService`)
  - 한국어 음식명 → 100g 기준 영양성분 AI 추정 (OpenAI Responses API)
  - `POST /api/v1/diet/ai-estimate` 엔드포인트
  
- AI 운동 추정 서비스 (`AiExerciseEstimationService`)
  - 한국어 운동명 → muscleGroup, exerciseType, MET값 AI 추정
  - `POST /api/v1/exercise/ai-estimate` 엔드포인트

- 운동 카탈로그 시드 데이터 (V11 마이그레이션)
  - 110개 운동 (근육군 14종, 한/영 이름, MET값 포함)

#### iOS
- 식단 검색 디바운스 및 요청 취소 로직
  - 500ms 디바운스, 진행 중 검색 취소, 느린 이전 응답 덮어쓰기 방지
  
- AI 운동 추정 폴백 (`AddExerciseSessionViewModel`)
  - `estimateWithAI()`, `addAiEstimatedExercise()` 메서드
  - `aiEstimateResult`, `isAiEstimating` 상태

- AI 영양 추정 폴백 (`AddDietLogViewModel`)
  - `estimateWithAI()`, `addAiEstimatedFood()` 메서드
  - `aiEstimateResult`, `isAiEstimating` 상태

### Fixed

- `FoodCatalogService` — 검색어 trim 정규화 추가

## [v0.2.0] - 2026-04-26

### Added

#### 백엔드
- Insights API (주간 회고, 변화 분석)
  - `GET /api/v1/insights/weekly-summary`
  - `GET /api/v1/insights/change-analysis`
  - InsightsService 21개 단위 테스트

#### iOS
- 주간 회고 화면 (`WeeklyRetrospectiveView`)
  - 주간 네비게이션 + 실데이터 연동
  
- 변화 분석 화면 (`ChangeAnalysisView`)
  - 기간 선택 프리셋 + 실데이터 연동

- 목표 수정 화면 (`EditGoalView`)

### Fixed

- `ProgressPhotoResponse.isBaseline` @JsonProperty 누락 버그 (직렬화)
- `ProgressPhotoView` onChange iOS 16 호환 시그니처 수정

## [v0.1.0] - 2026-04-09

### Added

- Spring Boot 프로젝트 초기 구성
- 인증 API (회원가입, 로그인, 토큰 갱신, 로그아웃)
- 사용자 API (프로필 조회/수정/삭제)
- 운동 기록 도메인 (카탈로그, 세션 CRUD)
- 식단 기록 도메인 (식사 CRUD, 외부 공공데이터 연동)
- 신체 측정 도메인 (CRUD)
- 진행 사진 업로드 (presigned URL MVP)
- 목표 도메인 (생성/목록/상세/수정/포기)
- iOS SwiftUI 기본 앱 구조
- MVVM 패턴 구현
- JWT 토큰 저장 및 관리 (Keychain)
- 주요 도메인 MockMvc 단위 테스트

---

**Version 기준:**
- Semantic Versioning (MAJOR.MINOR.PATCH) 따름
- 각 Phase 완성 또는 significant 기능 추가 시 마이너 버전 업
- 버그 픽스 및 소량의 개선은 패치 버전 업
