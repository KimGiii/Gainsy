# 백엔드 코드 리뷰 — 2026-05-21

**대상**: `backend/src/main/java/com/healthcare/` (156개 Java 파일)
**스택**: Spring Boot 3, Java 21, JPA/Hibernate, PostgreSQL, Redis, JWT, AWS S3, FCM
**리뷰어**: java-reviewer + security-reviewer 병렬 에이전트
**판정**: **REQUEST CHANGES** — CRITICAL 2건, HIGH 6건

---

## 🔴 CRITICAL

### C-1. 컨트롤러의 JWT 직접 파싱 — 검증 우회 위험 ✅ 해결 (2026-05-21)

`@CurrentUserId` 어노테이션 + `CurrentUserIdArgumentResolver` 도입으로 전 컨트롤러(12개) 통일:
- `security/CurrentUserId.java`, `CurrentUserIdArgumentResolver.java` 신규
- `common/config/WebMvcConfig.java` — 리졸버 등록
- 컨트롤러에서 `JwtTokenProvider` 직접 의존 및 `resolveUserId()` 헬퍼 모두 제거
- 컨트롤러 테스트 4개 — `setCustomArgumentResolvers` + `SecurityTestSupport`로 마이그레이션
- 237/238 테스트 통과 (남은 1건은 DB 의존 컨텍스트 로드 테스트, 무관)

---

### (원본 지적) C-1. 컨트롤러의 JWT 직접 파싱 — 검증 우회 위험

**파일**: `AuthController.java:43`, `BodyMeasurementController.java:135`, `ExerciseSessionController.java:91`, `GoalController.java:106` 외 다수

`JwtAuthenticationFilter`가 이미 `SecurityContextHolder`에 인증을 세팅함에도 컨트롤러가 `jwtTokenProvider.getUserId(token)`을 직접 호출. `validateToken()`을 거치지 않아 만료/조작 토큰 우회 위험 + NPE/500 위험.

**수정**: `@AuthenticationPrincipal`로 통일 (이미 `ProgressPhotoController`, `MealPhotoAnalysisController`에 적용된 패턴).

```java
public ResponseEntity<?> foo(@AuthenticationPrincipal CustomUserDetails user) {
    Long userId = user.getId();
}
```

### C-2. CORS 기본값 와일드카드

**파일**: `common/config/WebMvcConfig.java:11`

```java
@Value("${app.cors.allowed-origins:*}")  // 기본값 *
```

프로파일별 명시 설정 누락 시 모든 origin 허용. 기본값을 빈 문자열로 바꾸고 누락 시 시작 실패시키도록.

---

## 🟠 HIGH

### H-1. `RateLimitingFilter` X-Forwarded-For 무조건 신뢰

**파일**: `common/filter/RateLimitingFilter.java:68`

헤더를 매 요청 변경해 우회 가능. trusted proxy 검증 필요. 추가로 인메모리 `ConcurrentHashMap`은 멀티 인스턴스 환경에서 비동작 → Redis 기반으로 교체.

### H-2. `@Modifying` 쿼리에 `@Transactional` 누락

**파일**: `domain/diet/repository/FoodCatalogRepository.java:66,71`

호출 컨텍스트에 의존. 리포지토리에 `@Transactional` 명시 권장.

### H-3. GET 조회 API가 DB 쓰기 수행 (동시성 중복 INSERT 위험)

**파일**: `domain/goals/service/GoalService.java:124`

`getGoalProgress()`가 `upsertMissingWeeklyCheckpoints` 사이드이펙트 포함. 스케줄러나 생성 시점으로 분리.

### H-4. `NotificationService.sendWeeklySummaryToAll()` 대형 트랜잭션

**파일**: `common/notification/NotificationService.java:26`

전체 사용자 루프 + FCM 외부 호출이 단일 `@Transactional`. 사용자당 트랜잭션으로 분리, FCM은 트랜잭션 밖에서.

### H-5. JWT Access Token 24시간 만료

**파일**: `security/SecurityConstants.java:7`, `application.yml:60` (`access-token-expiry-hours: 24`)

탈취 시 24h 유효. 15분~1h + refresh 토큰 회전 권장.

### H-6. 페이징 size 상한 미설정

**파일**: `BodyMeasurementController:47`, `ExerciseSessionController:56`, `GoalController:47`

`size=100000` 같은 악성 요청으로 DB 과부하. `Math.min(size, 100)` 강제.

---

## 🟡 MEDIUM / LOW

| 위치 | 이슈 |
|---|---|
| `application.yml:60` | JWT secret 기본값(`dev-secret-key-...`) 하드코딩 — `${JWT_SECRET}`만 두고 미설정 시 시작 실패시키기 |
| `ExerciseSessionService:140`, `DietLogService:134` | catalog 조회 N+1 (`findAllById` 사용) |
| `WeeklyNotificationScheduler:19` | cron `0 0 0 * * MON` + UTC인데 주석은 KST 09시 → `zone="Asia/Seoul"` + `0 0 9 * * MON`으로 명시 |
| `GlobalExceptionHandler:92` | `log.error("Unhandled", e)` 전체 스택 로깅 — 메시지만 기록 권장 |
| `AuthService:149` | 사용자 입력값을 에러 메시지에 반사 |
| `ExerciseCatalogRepository:28` | LIKE `%`/`_` 미이스케이프 |
| `ProgressPhotoService:161` | storage key prefix 하드코딩 → 설정값 참조 |
| `SecurityConfig` | HSTS/X-Content-Type-Options/X-Frame-Options/Referrer-Policy 명시 설정 누락 |
| `application-local.yml` (untracked) | `.gitignore` 처리되어 git 미추적이지만, OpenAI/공공API 키 평문 — `.env` 또는 시크릿 매니저 권장 |

---

## 우선순위 권고

1. **C-1 즉시**: `@AuthenticationPrincipal`로 모든 컨트롤러 통일 (가장 광범위·반복 패턴)
2. **C-2, H-1, H-6**: 외부 공격 표면 — 짧은 PR로 한 번에 처리 가능
3. **H-3, H-4**: 리팩토링 필요 — 별도 이슈로 분리
4. 나머지는 점진적으로

---

## 요약 테이블

| 등급 | 건수 | 핵심 |
|------|------|------|
| CRITICAL | 2 | 컨트롤러 JWT 직접 파싱, CORS 기본값 와일드카드 |
| HIGH | 6 | IP 스푸핑 rate limit 우회, `@Modifying` 트랜잭션 누락, GET이 쓰기 수행, 대형 트랜잭션+외부 호출, JWT 24h, 페이지 크기 무제한 |
| MEDIUM/LOW | 9 | JWT 기본 시크릿, N+1, cron 혼동, 스택 로깅, 입력 반사, LIKE 미이스케이프, prefix 하드코딩, security headers, 로컬 API 키 평문 |
