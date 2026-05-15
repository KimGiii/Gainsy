# 프로젝트 현황 — 2026년 5월 15일

## 전체 진행률

```
Phase 0: 환경 구축              ████████████████████ 100%
Phase 1: 인증 & 사용자          ████████████████████ 100%
Phase 2: 운동 기록             ████████████████████ 100%
Phase 3: 식단 기록             ████████████████████ 100%
Phase 4: 신체 측정 & 진행 사진    ████████████████████ 100%
Phase 5: 목표 & 인사이트        ████████████████████ 100%
Phase 6: MVP 출시 준비          ████████████████████ 100%
```

## 현재 판단 기준

- 2026-05-15 기준 (최신), App Store 심사 제출 완료. iPad 13" 스크린샷·build 4 TestFlight 업로드·심사 제출 모두 완료. Phase 0~6 전체 100%. 심사 결과 대기 중.
- 2026-05-15 기준, App Store Connect 메타데이터(설명·키워드·스크린샷 5장·앱 심사 정보·연령 등급 9+·카테고리 건강및피트니스) 입력 완료, Privacy Labels 게시 완료, AdMob 통합(NSPrivacyTrackingDomains 추가, ITMS-91064 수정), prod 502 해결(200 응답 확인)으로 Phase 6을 85%로 설정했다.
- 2026-05-12 기준, 전체 화면에 어댑티브 컬러 토큰 적용(다크/라이트 모드 완전 지원), 식사 기록 수정(PUT API + iOS), 세션 만료 자동 로그아웃, Pull-to-refresh 전면 적용, DiaryView 완성으로 Phase 6을 본격 착수 상태로 전환했다.
- 2026-05-11 기준, Dynamic Type 지원(Typography 스케일 재구성), PrivacyInfo.xcprivacy 추가, 홈 대시보드 VoiceOver 지원, Terraform Stage 1 AWS 인프라(VPC/EC2/RDS/Redis/ECR) 프로비저닝 완료, CI/CD GitHub Actions 파이프라인 구축 완료로 Phase 6 착수를 확인했다.
- 2026-05-05 기준, Phase 5 FCM 완료(100%)를 확인하고, EXIF 제거·썸네일 생성 파이프라인(Phase 4 보완), ViewModel 의존성 프로토콜 추출(테스트 가능성 개선), DiaryView 착수로 Phase 6 준비를 시작했다.

## 최근 변경 사항 (2026-05-11 ~ 05-15: Phase 6 BLOCKER 완료 + 다크모드 + 접근성)

### 백엔드 / 인프라

- [x] `PUT /api/v1/diet/meals/{mealId}/logs/{logId}` — 식사 기록 수정 API 신규 추가
- [x] `AiNutritionEstimationService` 예외 시 폴백 응답 반환 (AI API 오류가 클라이언트로 전파되지 않도록 안정화)
- [x] `application-prod.yml` — Nginx 리버스 프록시 뒤에서 `X-Forwarded-*` 헤더 신뢰 설정 (`forward-headers-strategy: native`)
- [x] Terraform Stage 1 완전 프로비저닝 — VPC, EC2(t3.small), RDS(PostgreSQL 16), ElastiCache(Redis 7), ECR, S3(prod), Route 53
- [x] Route 53 호스팅 영역 + `api.gainsy.site` DNS A 레코드 (EIP 15.165.250.185) 추가
- [x] Nginx HTTPS 설정 — Let's Encrypt(Certbot) SSL, SSL 만료 2026-08-11, 자동 갱신 구성
- [x] EC2 user_data에 `api_domain` 변수 전달, Nginx 리버스 프록시 prod 설정 완성
- [x] LocalStack 0.0.0.0 바인딩 + `ensureBucketExists` 빈 제거, prod S3 설정 환경변수로 전환
- [x] Docker 컨테이너에서 LocalStack 접근 시 `host.docker.internal` 사용으로 S3 presigned URL 수정
- [x] IAM 정책 JSON 추가 (Terraform 운영자 권한, GitHub Actions 배포 권한)
- [x] GitHub Actions CI/CD 파이프라인 구축 완료 (`ci-backend.yml`, `ci-ios.yml`, `dev-to-prod.yml`)
- [x] `deploy-dev.yml` 삭제 (dev EC2 없음), `deploy-prod.yml` → `dev-to-prod.yml` 리네임

### iOS

- [x] 전체 뷰 어댑티브 컬러 토큰 적용 — `backgroundPrimary`, `backgroundPage`, `backgroundCard`, `textPrimary` 등 다크/라이트 완전 지원
- [x] 앱 레벨 `preferredColorScheme` 적용 — `AppContainer` 기반 테마 전환 동작
- [x] `Dynamic Type` 지원 — `Typography` 스케일 재구성, 전체 폰트 사이즈 유연화
- [x] 홈 대시보드 VoiceOver 지원 강화 — 접근성 레이블, 힌트, 그룹 지정
- [x] `PrivacyInfo.xcprivacy` — App Store Privacy Manifest 추가 (API 사용 이유 선언)
- [x] `Info.plist` 앱 메타데이터 및 권한 설명 업데이트 (카메라, 사진 라이브러리, 건강 등)
- [x] 식사 기록 수정 기능 — `EditMealLogView`/`EditMealLogViewModel` + `PUT` API 연결
- [x] 세션 만료 시 자동 로그아웃 — `APIClient` 401 수신 시 `AuthState` 초기화 후 온보딩 전환
- [x] Pull-to-refresh 전체 적용 — Home, Diary, Progress, Goals 탭
- [x] `DiaryView` 완성 — 날짜별 운동/식단/신체 카드, 캘린더 연동, 신체 변화 측정 버튼 조건부 숨김
- [x] 신체 변화 그래프 수정 — AreaMark 영역 이탈 수정, Y축 고정 범위, 현재/시작 체중 반전 수정, BMI 자동 계산 복구
- [x] 운동·식단 기록 화면, 다이어리, 탐색, 주간 회고, 변화 분석, 마이페이지 다크모드 Forest 톤 일관성 적용
- [x] HTTPS 도메인 전환 (`api.gainsy.site`) — `defaultBaseURL` 교체, `Info.plist` ATS 예외 블록 제거
- [x] `DEVELOPMENT_TEAM` = `HVVJG5AF82` 설정 (`project.yml`)
- [x] Swift 6 `MainActor` 격리 경고 수정
- [x] 앱 표시 이름 `Vitae` → `gainsy` (`CFBundleDisplayName`), App Store 등록명 `Gainsy`
- [x] App Icon 전체 사이즈 추가 (20pt~1024pt)
- [x] `ViewModel` 의존성 프로토콜 추출 — 테스트 주입 가능 구조로 전환
- [x] UI 테스트 환경 개선 + ViewModel 단위 테스트 25개 확보

### 문서

- [x] `docs/operations/DOMAIN_MIGRATION_GAINSY_SITE.md` — `api.gainsy.site` 도메인 전환 운영 가이드 추가
- [x] `docs/legal/privacy.html`, `terms.html` — GitHub Pages 기반 개인정보 처리방침/이용약관 페이지 추가

## 최근 변경 사항 (2026-05-04 FCM)

### 백엔드

- [x] `FcmConfig` — `FCM_CREDENTIALS_PATH` 기반 FirebaseApp 조건부 초기화 (mock/real 분기)
- [x] `FcmService` — FCM 메시지 발송 래퍼. FirebaseApp 없으면 MOCKED 반환 (ObjectProvider 패턴)
- [x] `NotificationService` — 주간 요약 알림 비즈니스 로직, 6일 이내 중복 발송 방지
- [x] `WeeklyNotificationScheduler` — 매주 월요일 KST 09:00 자동 발송 (`@ConditionalOnProperty`로 로컬 비활성화)
- [x] `V14__notification_logs.sql` — 알림 발송 이력 테이블 (type, status, fcm_token, error_message)
- [x] `UserRepository.findAllWithFcmToken()` — FCM 토큰 보유 사용자 조회 쿼리 추가
- [x] `@EnableScheduling` — `HealthCareApplication`에 스케줄링 활성화
- [x] `FcmServiceTest` 3개 + `NotificationServiceTest` 4개 추가 (7개 통과)

### iOS

- [x] `FcmTokenUploader` — `fcmTokenRefreshed` 수신 → `PATCH /api/v1/users/me` fcmToken 업로드
- [x] `AppContainer` — `FcmTokenUploader` 소유, 앱 생명주기 동안 토큰 갱신 자동 처리
- [x] `AppDelegate.userNotificationCenter(_:didReceive:)` — 알림 탭 시 `pushNotificationTapped` 브로드캐스트
- [x] `MainTabView` — `pushNotificationTapped` 수신, `WEEKLY_SUMMARY` 타입 → 탐색 탭으로 자동 이동

## 최근 변경 사항 (2026-05-04)

### 백엔드

- [x] `ProgressPhotoService.deletePhoto()` — 소유권 검증 후 soft-delete, ResourceNotFoundException / UnauthorizedException 분기
- [x] `DELETE /api/v1/body-measurements/photos/{photoId}` 엔드포인트 추가
- [x] `ProgressPhotoServiceTest` — deletePhoto 성공·notFound·타인 소유 3개 케이스 추가
- [x] `db/migration/V13__food_catalog_usage_count.sql` — `food_catalog` 테이블에 `usage_count BIGINT NOT NULL DEFAULT 0` 컬럼 추가
- [x] `FoodCatalog` 엔티티 — `usageCount` 필드 추가
- [x] `FoodCatalogRepository` — `searchAll()` 공개 검색, `incrementUsageCount()`, `decrementUsageCount()` 메서드 추가
- [x] `FoodCatalogResponse` — `usageCount`, `createdByUserId` 필드 포함
- [x] `CreateCustomFoodRequest` — Bean Validation 강화 (이름 100자 이내, HTML 특수문자 차단, 칼로리 0~9999)
- [x] `FoodCatalogService` — 같은 이름+카테고리 중복 검사, NFC 정규화, 연속 공백 축약
- [x] `DietLogService` — 식단 기록 생성/삭제 시 사용 식품별(distinct) usage_count +1/-1
- [x] `FoodCatalogController` — `POST /api/v1/diet/catalog` 누구나 등록 가능, 검색 공개화(`GET /api/v1/diet/catalog` Authorization required=false)
- [x] `AiNutritionController` — ObjectProvider 패턴으로 OPENAI_API_KEY 미설정 시 안전 처리

### iOS

- [x] `Date+Formatting.swift` — `Array.uniqued(by:)` 확장 메서드 추가
- [x] `APIEndpoint.swift` — `getExerciseCatalog` muscleGroup 파라미터 추가
- [x] `DietModels.swift` — `FoodCatalogItem` `usageCount`, `createdByUserId` 필드 추가
- [x] `AddDietLogViewModel` — `submitCustomFood()`, `showCustomFoodForm` 상태 추가
- [x] `AddDietLogView` — 빈 검색 결과 시 "직접 등록하기" 버튼, `AddCustomFoodView` 추가
- [x] `AddCustomFoodView` — 식품명, 카테고리(Picker), 칼로리(필수), 단백질/탄수/지방 입력 폼 + 검색어 자동 채움 + 성공 시 결과 prepend
- [x] `catalogResults`, `externalResults` — `displayName` 기준 `uniqued(by:)` 처리로 중복 제거
- [x] `MainTabView` — 탭 전환 시 이전 탭의 NavigationStack을 루트로 리셋
- [x] `APIEndpoint` — `deleteProgressPhoto(id:)` case 추가
- [x] `ProgressPhotoViewModel` — `deletePhoto()` 삭제 후 로컬 상태 즉시 반영, 비교 모드(compareMode 토글·선택·isSelected) 추가
- [x] `ProgressPhotoView` — 그리드 셀 context menu 삭제, 상세 화면 하단 삭제 버튼, 툴바 '비교' 토글 버튼
- [x] `compareBar` — 선택 안내 + '비교 보기' 버튼 (2장 선택 시 활성)
- [x] `PhotoCompareView` — 두 사진 좌우 분할 비교 화면 (날짜·체중 오버레이)
- [x] `AddExerciseSessionViewModel` / `AddExerciseSessionView` — 부위별 운동 탐색 그리드(12개 근육군 이모지 카드), 선택 시 해당 근육군 결과 필터

## 최근 변경 사항 (2026-04-28)

### 백엔드

- [x] `AiNutritionEstimationService` — 한국어 음식명 → 100g 기준 영양성분 AI 추정 (OpenAI Responses API 재사용)
- [x] `POST /api/v1/diet/ai-estimate` — 공공 API 검색 결과 없을 때 클라이언트 폴백용 엔드포인트
- [x] `AiExerciseEstimationService` — 한국어 운동명 → muscleGroup, exerciseType, MET값 AI 추정
- [x] `POST /api/v1/exercise/ai-estimate` — 카탈로그 검색 결과 없을 때 클라이언트 폴백용 엔드포인트
- [x] `V11__exercise_catalog_seed.sql` — 110개 운동 시드 데이터 (근육군 14종, 한/영 이름, MET값 포함)
- [x] 두 AI 서비스 모두 `@ConditionalOnExpression`으로 `OPENAI_API_KEY` 미설정 시 자동 비활성화

### iOS

- [x] `APIEndpoint` — `.aiEstimateFood`, `.aiEstimateExercise`, `.createCustomFood`, `.createCustomExercise` 4개 case 추가
- [x] `DietModels.swift` — `AiNutritionEstimateResponse`, `AiNutritionEstimateRequest` 모델 추가
- [x] `ExerciseModels.swift` — `AiExerciseEstimateResponse`, `AiExerciseEstimateRequest` 모델 추가
- [x] `AddDietLogViewModel` — `estimateWithAI()`, `addAiEstimatedFood()` 메서드 + `aiEstimateResult`, `isAiEstimating` 상태 추가
- [x] `AddDietLogViewModel` — 식품 검색 500ms 디바운스, 진행 중 검색 취소, 느린 이전 응답 덮어쓰기 방지 로직 추가
- [x] `AddDietLogView` / `FoodSearchSheet` — `onChange` 즉시 호출 제거, `return` 즉시 검색 유지, 검색어 삭제 시 결과 초기화 경로 통일
- [x] `AddExerciseSessionViewModel` — `estimateWithAI()`, `addAiEstimatedExercise()` 메서드 + `aiEstimateResult`, `isAiEstimating` 상태 추가
- [x] `AddDietLogViewModelTests` — 디바운스, 즉시 검색, 검색어 삭제, 느린 응답 역전 방지 시나리오 단위 테스트 추가

### 규제 검토

- [x] 식약처 지침 확인 — 칼로리/식단 추적 앱은 비의료기기로 분류, AI 추정값 제공 허용
- [x] AI기본법(2026) 대응 — 응답에 `isAiEstimated: true` + `disclaimer` 필드 포함, 사용자 수정 후 저장 플로우 설계

## 최근 변경 사항 (2026-04-26)

### 백엔드

- [x] `InsightsControllerTest` 10개 추가 — 주간 회고 weekOffset, 빈 데이터, 401 인증 오류, 날짜 유효성 검증 등
- [x] `InsightsServiceTest` 11개 추가 — 델타 반올림(2자리), ENDURANCE 목표 스킵, WEIGHT_LOSS 달성률 계산 등
- [x] `ProgressPhotoResponse.isBaseline` `@JsonProperty` 누락 버그 수정 (직렬화 시 `is` prefix 탈락 방지)

### iOS

- [x] 탐색 탭(`ExploreView`)에서 `WeeklyRetrospectiveView`, `ChangeAnalysisView` 진입점 연결
- [x] `ProgressPhotoView` `onChange` iOS 16 호환 시그니처 수정
- [x] `DiaryView` 중복 `HistoryCalendarView`/`HistoryCalendarViewModel` 파일 삭제

## 최근 변경 사항 (2026-04-23)

### 백엔드

- [x] `InsightsController` / `InsightsService` 신규 구현 — `GET /api/v1/insights/weekly-summary`, `GET /api/v1/insights/change-analysis`
- [x] `GoalService`: ENDURANCE 진행률을 운동 세션 기간 합산으로 계산하는 `loadExercisePoints()` 추가
- [x] `GoalSummary.percentComplete` 목록 조회 시 읽기 전용 경량 계산(`calculatePercentCompleteReadOnly`) 적용
- [x] `GoalProgressResponse` `weeklyRateTarget` 필드 추가
- [x] `SecurityConfig`: `RestAuthenticationEntryPoint`, `RestAccessDeniedHandler` JSON 응답 적용
- [x] `JwtSecurityIntegrationTest` 추가 — 인증 없음/무효 토큰/유효 토큰 시나리오 검증
- [x] Redis 직렬화 회귀 케이스 및 비교 방식 안정화

### iOS

- [x] `InsightsModels.swift` — `WeeklySummaryResponse`, `ChangeAnalysisResponse` 모델 정의
- [x] `APIEndpoint` — `.getWeeklySummary`, `.getChangeAnalysis` case 추가
- [x] `WeeklyRetrospectiveView`/`ViewModel` — 주간 네비게이션 + 실데이터 연동 완성
- [x] `ChangeAnalysisView`/`ViewModel` — 기간 선택 프리셋 + 실데이터 연동 완성
- [x] `EditGoalView`/`EditGoalViewModel` — `GoalProgressView`에서 목표 수정 진입점 추가
- [x] `GoalModels`: `GoalProgressResponse.weeklyRateTarget` 필드 반영

## 최근 변경 사항 (2026-04-22)

### 백엔드

- [x] `AuthController`: `@AuthenticationPrincipal` 대신 Bearer 헤더 직접 해석으로 로그아웃 경로 정리
- [x] `UserController`: `GET/PATCH/DELETE /api/v1/users/me`에서 Bearer 헤더 직접 검증
- [x] `AuthControllerTest` 추가 — 회원가입/로그인/토큰 갱신/로그아웃 MockMvc 단위 테스트
- [x] `UserControllerTest` 추가 — 프로필 조회/수정/삭제 MockMvc 단위 테스트
- [x] `JwtSecurityIntegrationTest` 추가 — 실제 `SecurityFilterChain` + `JwtAuthenticationFilter` 기준 인증 없음/무효 토큰/유효 토큰 시나리오 검증
- [x] `SecurityConfig`: `RestAuthenticationEntryPoint`, `RestAccessDeniedHandler` 연결로 보안 실패 응답을 JSON 형식으로 통일
- [x] `ProgressPhotoController`: 경로를 `/api/v1/body-measurements/photos`로 통일
- [x] `FoodCatalogRepository`: 공백 무시 검색 + prefix 우선 정렬로 식품 검색 품질 개선
- [x] `FoodCatalogService`: 검색어 trim 정규화 및 테스트 추가
- [x] `ExternalFoodResult`: `@Jacksonized` 추가, 외부 DTO 역직렬화 안정화
- [x] `V10__normalize_endurance_goal_units_to_minutes.sql`: endurance 목표/체크포인트의 초 단위를 분 단위로 정규화
- [x] `docs/design-docs/DB_SCHEMA.md`: endurance 목표 단위를 `minutes` 기준으로 업데이트

### iOS

- [x] `ProgressPhotoModels`, `ProgressPhotoViewModel`, `ProgressPhotoView`, `AddProgressPhotoView` 추가
- [x] 진행 사진 업로드 플로우를 presigned URL 발급 → S3 PUT → 메타데이터 등록 3단계로 연결
- [x] 신체 측정 추세 그래프를 `GET /api/v1/body-measurements/range`, `GET /api/v1/body-measurements/at-or-before` 기반으로 연동
- [x] `APIEndpoint`: 진행 사진 업로드 URL 발급/등록/목록 조회 계약 추가
- [x] `GoalModels`: endurance 단위를 분 기준으로 표시하고 목표 타입별 주간 변화량 규칙 반영
- [x] `AddGoalViewModel`, `AddGoalView`: 목표 단위/주간 변화량 입력 UX 보정
- [x] `HomeViewModel`: 활성 목표 진행률 API 연동으로 홈 대시보드 정확도 개선
- [x] `AddExerciseSessionViewModel`, `AddExerciseSessionView`: 운동 시간 입력 및 ISO-8601 시작/종료 시각 전송 지원
- [x] `MyPageViewModel`, `MyPageView`: 프로필 조회/수정/삭제 실데이터 연결
- [x] `HomeView`, `RecordHubView`, `MyPageView`: 디자인 시스템을 활용한 UI 개편
- [x] `ios/Configs/Debug.xcconfig`, `Release.xcconfig`: 환경별 iOS 설정 파일 추가

### 문서 / 리서치

- [x] `docs/design-docs/EXERCISE_EXTERNAL_INTEGRATION.md`: 운동 외부 데이터 연동 원칙과 채택안 정리
- [x] `docs/references/EXERCISE_API_SURVEY_2026-04-22.md`: 운동 종목·칼로리 API 조사 문서 추가
- [x] `gan-harness/spec.md`, `gan-harness/eval-rubric.md`: 평가용 스펙과 루브릭 추가
- [x] `CLAUDE.md`: 저장소 작업 규칙 정리

## 현재 구현 상태

### 백엔드 완료

- [x] FCM 알림 연결 (FcmConfig + FcmService + NotificationService + WeeklyNotificationScheduler + notification_logs V14)
- [x] Spring Boot 프로젝트 구성, Flyway, PostgreSQL, Redis, JWT 보안 기본 구조
- [x] 인증 API (register/login/refresh/logout) + AuthController MockMvc 단위 테스트
- [x] 사용자 API (me 조회/수정/삭제) + UserController MockMvc 단위 테스트
- [x] 운동 기록 도메인 (카탈로그, 세션 CRUD)
- [x] 식단 기록 도메인 (식사 CRUD, 식품 검색 품질 보정, 외부 공공데이터 연동)
- [x] AI 사진 기반 식단 분석 워크플로 (OpenAI + fallback)
- [x] AI 텍스트 기반 영양 추정 (`POST /api/v1/diet/ai-estimate`) — 한국어 음식명 → 영양성분
- [x] AI 텍스트 기반 운동 추정 (`POST /api/v1/exercise/ai-estimate`) — 한국어 운동명 → MET/분류
- [x] 운동 카탈로그 시드 데이터 110개 (V11 마이그레이션, 근육군별 한/영 이름 + MET값)
- [x] 사용자 직접 식품 등록 (`POST /api/v1/diet/catalog`) — 누구나 공용 DB에 등록 가능, 중복 방지
- [x] 식품 사용 횟수 추적 (`usage_count`) — 식단 기록 추가/삭제 시 자동 카운팅, 검색 시 정렬
- [x] 신체 측정 도메인 (CRUD + atOrBefore 쿼리 + TDD 20개)
- [x] 진행 사진 업로드 MVP (presigned URL, 메타데이터 저장, signed download)
- [x] 진행 사진 삭제 API (`DELETE /api/v1/body-measurements/photos/{photoId}`, soft-delete, 소유권 검증)
- [x] S3/LocalStack 설정, Terraform AWS 골격
- [x] 목표 도메인 (생성/목록/상세/수정/포기, ENDURANCE 운동 세션 기반 진행률, endurance 단위 minutes 정규화)
- [x] 인사이트 도메인 (weekly-summary, change-analysis API 구현)
- [x] 서비스 단위 테스트 다수 (Auth, BodyMeasurement, ProgressPhoto, MealPhotoAnalysis, GoalService, InsightsService) + 컨트롤러 단위 테스트 (Auth, User, Goal, Insights)

### iOS 완료

- [x] FCM 토큰 업로드 (FcmTokenUploader) + 푸시 알림 수신 라우팅 (WEEKLY_SUMMARY → 탐색 탭)
- [x] 인증 플로우 (회원가입/로그인/토큰 관리)
- [x] 홈 대시보드 (실데이터 연결 + 활성 목표 진행률 반영)
- [x] 운동 기록 화면 (세션 기록, 히스토리)
- [x] 식단 기록 화면 (식품 검색, AI 사진 진입점, 실데이터 연결, AI 영양 추정 폴백 연동)
- [x] 식단 기록 화면 — 검색 입력 디바운스 및 요청 취소 반영
- [x] 운동 기록 화면 — AI 운동 추정 폴백 연동 (`estimateWithAI`, `addAiEstimatedExercise`)
- [x] 신체 측정 화면 (체중 + 5개 둘레 입력, LatestStatsCard, 기간/지표별 추세 그래프)
- [x] 진행 사진 화면 (목록/상세/업로드/삭제/비교)
- [x] `PhotoCompareView` — 같은 부위 before/after 좌우 분할 비교 (날짜·체중 오버레이)
- [x] 목표 설정 화면 (GoalSettingView, AddGoalView, EditGoalView)
- [x] 목표 진행 화면 (GoalProgressView 완전 구현)
- [x] 마이페이지 화면 (프로필 조회/수정/계정 삭제)
- [x] 주간 회고 화면 (WeeklyRetrospectiveView, 주간 네비게이션 + 실데이터 연동)
- [x] 변화 분석 화면 (ChangeAnalysisView, 기간 선택 프리셋 + 실데이터 연동)
- [x] 탐색 탭 진입점 (ExploreView → WeeklyRetrospectiveView / ChangeAnalysisView)
- [x] 식품 직접 등록 (AddCustomFoodView, 검색 결과 없음 시 자동 제공, prepend + 자동 선택)
- [x] 검색 결과 중복 제거 (catalogResults, externalResults displayName 기준)

### 구현은 되었지만 보완이 필요한 항목

- [x] 컨트롤러/보안 테스트: Auth/User/Goal 단위 테스트, JWT 보안 체인 통합 테스트, 도메인별 권한 경계 시나리오 검증 완료
- [~] iOS 진행 사진: 촬영 시점 선택, 썸네일 상태 fallback 개선 필요 (삭제/비교는 완료)
- [x] iOS 테스트 타깃: `APIClient` 토큰 refresh/401 재시도, 핵심 ViewModel, 온보딩/로그인/메인 탭 UI smoke 테스트 포함 전체 `xcodebuild test` 통과

### 아직 미구현 또는 미완성

- [x] HTTPS 도메인 전환 (`api.gainsy.site`)
- [x] 코드 사이닝 설정 (`DEVELOPMENT_TEAM`, Bundle ID `com.kingloo.gainsy.ios`)
- [x] Firebase / FCM 연결 (APNs Production 키 업로드, FCM 서비스 계정 EC2 배치)
- [x] 개인정보 처리방침·이용약관 (GitHub Pages)
- [x] `PrivacyInfo.xcprivacy` Privacy Manifest
- [x] App Icon 전체 사이즈
- [x] AWS 인프라 Terraform 완전 프로비저닝
- [x] CI/CD GitHub Actions 파이프라인 (백엔드·iOS CI, dev→prod 배포)
- [x] 다크모드 전면 도입 + Dynamic Type + VoiceOver 접근성 강화
- [x] **dev → prod PR merge** 완료
- [x] prod 502 해결 (200 응답 확인)
- [x] App Store Connect 스크린샷 (6.7" iPhone 5장 업로드 완료)
- [x] 앱 설명·키워드·부제 입력 완료
- [x] 연령 등급 9+ 설정 완료
- [x] 카테고리·가격(무료) 설정 완료
- [x] App Review 정보 입력 (데모 계정, 리뷰 노트) 완료
- [x] Privacy Labels 전체 게시 완료 (Data Used to Track You → Yes)
- [x] **iPad 13" 스크린샷 업로드** 완료
- [x] **Xcode Archive build 4 → TestFlight 업로드** 완료
- [x] **심사 제출** 완료 ← App Store 심사 대기 중
- [ ] TestFlight 외부 테스터 5~10명 초대 (선택)

## Phase별 상세 상태

### Phase 0: 환경 구축 — 완료

### Phase 1: 인증 & 사용자 — 완료

- 기능 구현 완료
- Auth/User 컨트롤러 MockMvc 단위 테스트 완료
- JWT 필터 및 보안 체인 통합 테스트 완료

### Phase 2: 운동 기록 — 완료

### Phase 3: 식단 기록 — 100%

- AI 사진 분석 워크플로 포함 구현 완료
- 검색 품질 보정(공백 무시, prefix 우선 정렬, usage_count DESC) 반영
- 식단 검색 입력 500ms 디바운스 + 이전 요청 취소 반영으로 외부 API 과호출 완화
- AI 텍스트 추정 폴백(`POST /api/v1/diet/ai-estimate`) + iOS ViewModel 연동 완료
- 사용자 직접 식품 등록(`POST /api/v1/diet/catalog`) + iOS `AddCustomFoodView` 완료
- 식품 검색 공개화(`GET /api/v1/diet/catalog` Authorization required=false) 완료
- 식단 기록 추가/삭제 시 사용 식품별 usage_count 자동 카운팅 완료
- 남은 것: 외부 API 장애 대응 회귀 테스트, AI 추정 결과 표시 View UI (배지·disclaimer)

### Phase 4: 신체 측정 & 진행 사진 — 100%

- 백엔드: 측정 CRUD + atOrBefore + 진행 사진 presigned URL MVP + 경로 정합성 + isBaseline 직렬화 버그 수정 + 사진 삭제 API(soft-delete, 소유권 검증) + EXIF 제거/썸네일 생성/업로드 완료 검증 완료
- iOS: 모든 둘레 입력 필드 + LatestStatsCard + 진행 사진 목록/상세/업로드 + iOS 16 호환 수정 + 삭제 UX(context menu + 상세화면 버튼) + 비교 모드(PhotoCompareView) 완료
- 보완 사항(출시 준비 단계): 촬영 시점/메모 UX, 썸네일 상태 fallback 문구 정리

### Phase 5: 목표 & 인사이트 — 100%

- 백엔드: 목표 CRUD + 진행률 API + ENDURANCE 운동 세션 기반 계산 + Insights API(weekly-summary/change-analysis) + FCM 알림(FcmService + NotificationService + WeeklyNotificationScheduler) + notification_logs V14 완료
- iOS: GoalProgressView, EditGoalView, WeeklyRetrospectiveView, ChangeAnalysisView 실데이터 연동 + 탐색 탭 진입점 + FcmTokenUploader + 푸시 알림 라우팅 완료
- 테스트: `HomeViewModel`, `GoalProgressViewModel`, `ProgressPhotoViewModel`, `MyPageViewModel`, `APIClient` refresh/401 재시도, 온보딩/로그인/메인 탭 smoke 검증 완료

### Phase 6: MVP 출시 준비 — 100% ✅

## 현재 알려진 이슈

- Gradle deprecation warning 잔존 (테스트 실패와 무관)
- iOS 테스트 실행 시 로컬 개발 환경에서 `GoogleService-Info.plist` 미설정/Firebase dev skip 로그와 APNs entitlement 경고가 출력되지만 테스트 실패와 무관하다.

## 권장 다음 단계

### App Store 심사 대기 중

심사 제출 완료 (2026-05-15). Apple 심사 결과를 기다리는 중. 통상 1~3 영업일 소요.

### 출시 후

1. H1 prod yml 강화 (스레드 튜닝, Rate limiting, 로그 JSON)
2. H6 Health Check (Actuator readiness/liveness, ALB)
3. M1~M4 UX 보강 (진행 사진 재시도, APNs 실기기 테스트 등)

### 잔여 UX 보강 (선택)

- 진행 사진 업로드 실패 fallback 문구 및 재시도 UX
- 빈 데이터 상태·최초 기록 유도 UX (신체 측정 히스토리)
- 핵심 플로우 UI 테스트 (운동 기록, 식단 기록, 신체 측정)

### 문서 운영 원칙

- 장기 일정과 이상적 완성 정의는 `docs/exec-plans/MVP_ROADMAP.md`
- 실제 구현 진척과 현재 우선순위는 이 문서와 `docs/exec-plans/BACKEND_TODO.md`에서 관리
- 백엔드-iOS 연동 단위 작업 흐름은 `docs/exec-plans/BACKEND_IOS_SYNC_WORKFLOW.md`를 기준으로 관리

---

**마지막 업데이트**: 2026-05-15 (Phase 6 100% — App Store 심사 제출 완료, 심사 결과 대기 중)
