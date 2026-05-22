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

### C-2. CORS 기본값 와일드카드 ✅ 해결 (2026-05-21)

- `WebMvcConfig` — `@Value("${app.cors.allowed-origins}")` 기본값 제거. 누락 또는 `*` 사용 시 `IllegalStateException`으로 시작 실패.
- `application.yml` — 로컬 기본 `http://localhost:3000,http://localhost:5173` 명시(환경변수 `CORS_ALLOWED_ORIGINS`로 override).
- `application-prod.yml` — 기존 명시값 유지.

---

### (원본 지적) C-2. CORS 기본값 와일드카드

**파일**: `common/config/WebMvcConfig.java:11`

```java
@Value("${app.cors.allowed-origins:*}")  // 기본값 *
```

프로파일별 명시 설정 누락 시 모든 origin 허용. 기본값을 빈 문자열로 바꾸고 누락 시 시작 실패시키도록.

---

## 🟠 HIGH

### H-1. `RateLimitingFilter` X-Forwarded-For 무조건 신뢰 ✅ 해결 (2026-05-21)

- `RateLimitingFilter`에서 X-Forwarded-For 직접 파싱 코드 제거. `request.getRemoteAddr()`만 사용.
- 프로덕션은 `application-prod.yml`의 `server.forward-headers-strategy: native` + 신뢰된 프록시(Nginx)가 `getRemoteAddr()`에 실 클라이언트 IP를 반영하므로 별도 헤더 신뢰 코드가 불필요.
- `app.rate-limit.trust-forwarded-headers` 설정 추가(기본 false, prod true) — 정책 가시화.
- `RateLimitingFilter`를 `@Component`로 변환해 SecurityConfig가 빈으로 주입받도록 정리.
- (남은 TODO) 인메모리 `ConcurrentHashMap` → 멀티 인스턴스 환경 대비 Redis 기반으로 교체.

---

### (원본 지적) H-1. `RateLimitingFilter` X-Forwarded-For 무조건 신뢰

**파일**: `common/filter/RateLimitingFilter.java:68`

헤더를 매 요청 변경해 우회 가능. trusted proxy 검증 필요. 추가로 인메모리 `ConcurrentHashMap`은 멀티 인스턴스 환경에서 비동작 → Redis 기반으로 교체.

### H-2. `@Modifying` 쿼리에 `@Transactional` 누락

**파일**: `domain/diet/repository/FoodCatalogRepository.java:66,71`

호출 컨텍스트에 의존. 리포지토리에 `@Transactional` 명시 권장.

### H-3. GET 조회 API가 DB 쓰기 수행 (동시성 중복 INSERT 위험) ✅ 해결 (2026-05-21)

- `GoalService.getGoalProgress` — 메서드 단위 `@Transactional` 제거 → 클래스 단위 `readOnly = true` 적용. `upsertMissingWeeklyCheckpoints` 호출 삭제.
- `GoalService.maintainCheckpointsForGoal(Long goalId)` 신규 — 목표별 별도 `@Transactional` 진입점.
- `GoalRepository.findActiveGoalIds()` 추가.
- `GoalCheckpointScheduler` 신규 — 매일 KST 03:00 활성 목표를 순회하며 누락 체크포인트를 채워 넣는다. 목표별 try/catch로 단일 실패가 다른 목표에 전파되지 않음.
- 기존 `uq_goal_checkpoints_weekly` 유니크 인덱스가 DB 단에서 중복 INSERT를 차단.

---

### (원본 지적) H-3. GET 조회 API가 DB 쓰기 수행 (동시성 중복 INSERT 위험)

**파일**: `domain/goals/service/GoalService.java:124`

`getGoalProgress()`가 `upsertMissingWeeklyCheckpoints` 사이드이펙트 포함. 스케줄러나 생성 시점으로 분리.

### H-4. `NotificationService.sendWeeklySummaryToAll()` 대형 트랜잭션 ✅ 해결 (2026-05-21)

- 메서드 단위 `@Transactional` 제거 — 전체 사용자 루프가 단일 트랜잭션으로 묶이지 않음.
- 사용자별 try/catch — 한 사용자의 FCM 실패가 다른 사용자에게 전파되지 않음. `failed` 카운터 추가.
- FCM 외부 HTTP 호출이 DB 트랜잭션 밖에서 실행됨. `notificationLogRepository.save()`는 Spring Data JPA의 기본 메서드 트랜잭션으로 짧게 처리.

---

### (원본 지적) H-4. `NotificationService.sendWeeklySummaryToAll()` 대형 트랜잭션

**파일**: `common/notification/NotificationService.java:26`

전체 사용자 루프 + FCM 외부 호출이 단일 `@Transactional`. 사용자당 트랜잭션으로 분리, FCM은 트랜잭션 밖에서.

### H-5. JWT Access Token 24시간 만료 ✅ 해결 (2026-05-21)

- `application.yml` — `access-token-expiry-hours: 24` → `1`. JWT secret 기본값 제거(`${JWT_SECRET}`만), 미설정 시 시작 단계 `PlaceholderResolutionException`.
- `JwtTokenProvider` — 만료시간을 `@Value`로 주입받아 환경별 조정 가능. `getAccessTokenExpirySeconds()` 노출.
- `SecurityConstants.ACCESS_TOKEN_EXPIRY_MS`/`REFRESH_TOKEN_EXPIRY_MS` 상수 제거 — 설정으로 단일화. `AuthService`에서 상수 참조 → provider 메서드로 교체.
- iOS `APIClient`는 만료 30초 이내 선제 refresh + 401 응답 시 1회 재시도 + 동시 호출 단일 refresh 보장 → 1h 짧은 TTL 안전.

---

### (원본 지적) H-5. JWT Access Token 24시간 만료

**파일**: `security/SecurityConstants.java:7`, `application.yml:60` (`access-token-expiry-hours: 24`)

탈취 시 24h 유효. 15분~1h + refresh 토큰 회전 권장.

### H-6. 페이징 size 상한 미설정 ✅ 해결 (2026-05-21)

- `common/web/PageRequests` 유틸 신규 — `MAX_PAGE_SIZE=100`, `DEFAULT_PAGE_SIZE=20`, 음수/0 보정.
- 6개 컨트롤러(`GoalController`, `DietLogController`, `ExerciseSessionController`, `BodyMeasurementController`, `ProgressPhotoController`, `ExternalFoodController`)에서 `PageRequest.of(page, size)` → `PageRequests.of(page, size)`로 통일.

---

### (원본 지적) H-6. 페이징 size 상한 미설정

**파일**: `BodyMeasurementController:47`, `ExerciseSessionController:56`, `GoalController:47`

`size=100000` 같은 악성 요청으로 DB 과부하. `Math.min(size, 100)` 강제.

---

## 🟡 MEDIUM / LOW

| 위치 | 이슈 |
|---|---|
| ~~`application.yml:60`~~ ✅ | JWT secret 기본값(`dev-secret-key-...`) 하드코딩 — `${JWT_SECRET}`만 두고 미설정 시 시작 실패시키기 — **2026-05-21 해결**(H-5와 함께 처리) |
| `ExerciseSessionService:140`, `DietLogService:134` | catalog 조회 N+1 (`findAllById` 사용) |
| `WeeklyNotificationScheduler:19` | cron `0 0 0 * * MON` + UTC인데 주석은 KST 09시 → `zone="Asia/Seoul"` + `0 0 9 * * MON`으로 명시 |
| `GlobalExceptionHandler:92` | `log.error("Unhandled", e)` 전체 스택 로깅 — 메시지만 기록 권장 |
| `AuthService:149` | 사용자 입력값을 에러 메시지에 반사 |
| `ExerciseCatalogRepository:28` | LIKE `%`/`_` 미이스케이프 |
| `ProgressPhotoService:161` | storage key prefix 하드코딩 → 설정값 참조 |
| ~~`SecurityConfig`~~ ✅ | HSTS/X-Content-Type-Options/X-Frame-Options/Referrer-Policy 명시 설정 누락 — **2026-05-21 해결**(`.headers(...)` 체인 추가: HSTS 1년 + includeSubDomains + preload, content-type-options nosniff, X-Frame-Options DENY, Referrer-Policy strict-origin-when-cross-origin, XSS-Protection 0) |
| `application-local.yml` (untracked) | `.gitignore` 처리되어 git 미추적이지만, OpenAI/공공API 키 평문 — `.env` 또는 시크릿 매니저 권장 |

---

## 진행 현황 (2026-05-21 기준)

| 등급 | 항목 | 상태 |
|---|---|---|
| CRITICAL | C-1 컨트롤러 JWT 직접 파싱 | ✅ 해결 |
| CRITICAL | C-2 CORS 기본값 와일드카드 | ✅ 해결 |
| HIGH | H-1 RateLimitingFilter X-Forwarded-For 신뢰 | ✅ 해결 (인메모리 → Redis 교체는 후속) |
| HIGH | H-2 `@Modifying` 쿼리에 `@Transactional` 누락 | ⏳ 미해결 |
| HIGH | H-3 GET 조회가 DB 쓰기 수행 | ✅ 해결 |
| HIGH | H-4 NotificationService 대형 트랜잭션 | ✅ 해결 |
| HIGH | H-5 JWT Access Token 24h 만료 | ✅ 해결 |
| HIGH | H-6 페이징 size 상한 미설정 | ✅ 해결 |
| MEDIUM/LOW | JWT 기본 시크릿 | ✅ 해결 (H-5와 함께) |
| MEDIUM/LOW | Security headers (HSTS 등) | ✅ 해결 |
| MEDIUM/LOW | 나머지 7건 (N+1, cron, 스택 로깅, 입력 반사, LIKE 이스케이프, prefix, 로컬 API 키) | ⏳ 미해결 |

**해결**: CRITICAL 2/2, HIGH 5/6, MEDIUM/LOW 2/9
**남음**: H-2 + MEDIUM/LOW 7건 + H-1 후속(Redis 전환)

---

## 우선순위 권고 (남은 작업)

### 1순위 — 영속성·트랜잭션 정합성
- **H-2** `FoodCatalogRepository:66, 71` — `@Modifying` 메서드에 `@Transactional` 명시. 호출 컨텍스트 의존 제거.
- **M(N+1)** `ExerciseSessionService:140` (`getSessionById`), `DietLogService:134` (`getDietLogById`) — 세트/식품 항목별 `catalogRepository.findById` 루프를 `findAllById(idSet)` + 인메모리 매핑으로 교체.

### 2순위 — 운영 신뢰성
- **M(`WeeklyNotificationScheduler:19`)** cron 표현식 명시 — `zone = "Asia/Seoul"` + `"0 0 9 * * MON"`. 동작 동등하나 의도 가시화.
- **M(`GlobalExceptionHandler:92`)** `log.error("Unhandled", e)` → `log.error("Unhandled: {}", e.getMessage())`로 전체 스택 노출 축소(필요시 ERROR 레벨에서 trace는 유지하고 메시지만 필터링).
- **H-1 후속** 인메모리 `ConcurrentHashMap` 기반 rate limit → Redis 기반(Bucket4j-Redis 또는 직접 구현)으로 교체. 멀티 인스턴스 환경에서만 실제 영향.

### 3순위 — 작은 위생
- **M(`AuthService:149`)** `parseSex` 에러 메시지에서 사용자 입력값 반사 제거.
- **M(`ExerciseCatalogRepository:28`)** LIKE 쿼리에서 `%` / `_` 이스케이프(`ESCAPE '\'` 절 + 입력 sanitization).
- **M(`ProgressPhotoService:161`)** `"progress-photos/" + userId + "/"` 하드코딩 → `app.s3.upload-prefix` 설정값 참조.
- **M(`application-local.yml`)** 로컬 OpenAI/공공API 키를 `.env` 또는 시크릿 매니저로 분리. (git 미추적이지만 평문 파일 자체를 정리.)

---

## 요약 테이블 (원본 지적)

| 등급 | 건수 | 핵심 |
|------|------|------|
| CRITICAL | 2 | 컨트롤러 JWT 직접 파싱, CORS 기본값 와일드카드 |
| HIGH | 6 | IP 스푸핑 rate limit 우회, `@Modifying` 트랜잭션 누락, GET이 쓰기 수행, 대형 트랜잭션+외부 호출, JWT 24h, 페이지 크기 무제한 |
| MEDIUM/LOW | 9 | JWT 기본 시크릿, N+1, cron 혼동, 스택 로깅, 입력 반사, LIKE 미이스케이프, prefix 하드코딩, security headers, 로컬 API 키 평문 |
