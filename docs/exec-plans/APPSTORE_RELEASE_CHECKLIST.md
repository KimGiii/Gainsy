# App Store 출시 준비 체크리스트

**최종 업데이트**: 2026-05-16  
**현재 Phase 6 진행률**: 100% ✅ 심사 제출 완료 · 운영 보강 진행 중

## 상황 요약

Phase 0~6 모두 100% 완료. App Store 심사 제출 완료 (2026-05-15). 심사 결과 대기 중 (통상 1~3 영업일).

---

## 🚨 차단(BLOCKER) — 이거 해결 안 하면 앱스토어 심사 거부 또는 출시 불가

### B1. iOS — HTTPS 전환 ✅ 완료
- `api.gainsy.site` (Route 53 + Let's Encrypt, EIP 15.165.250.185)
- `Release.xcconfig` → `https://api.gainsy.site`
- `Info.plist` ATS 예외 블록 제거 완료
- SSL 만료: 2026-08-11, 자동 갱신 설정됨

### B2. iOS — 코드 사이닝 ✅ 완료
- `DEVELOPMENT_TEAM = HVVJG5AF82`
- Bundle ID: `com.kingloo.gainsy.ios` (App Store Connect 등록 완료)
- Distribution Certificate + App Store Provisioning Profile: Xcode Archive 시 자동 발급 확인 필요

### B3. iOS — App Icon ✅ 완료
- 20pt ~ 1024pt 전체 사이즈 추가 완료
- 마케팅 아이콘 1024×1024 알파 없음 확인 완료

### B4. Firebase 구성 ✅ 완료
- `GoogleService-Info.plist` → `.gitignore` 처리, Release 빌드 포함
- APNs Production 키(.p8) Firebase 콘솔 업로드 완료 (Team ID: HVVJG5AF82)
- FCM 서비스 계정 JSON → EC2 `/etc/healthcare/fcm-credentials.json` 배치 완료

### B5. 개인정보 처리방침/이용약관 URL ✅ 완료
- 개인정보 처리방침: `https://kimgiii.github.io/health-care/docs/legal/privacy.html`
- 이용약관: `https://kimgiii.github.io/health-care/docs/legal/terms.html`
- GitHub Pages(prod 브랜치 `docs/legal/`) 서빙 완료
- 앱 내 마이페이지 링크 노출: 확인 필요

### B6. App Store Connect Privacy Nutrition Labels ✅ 완료
- [x] `PrivacyInfo.xcprivacy` — 전체 데이터 타입 선언 완료 (이메일, 닉네임, 건강, 운동, 사진, 식단, User ID, Device ID, 광고 ID)
- [x] `NSPrivacyTrackingDomains` — AdMob 추적 도메인 4개 추가 (ITMS-91064 수정)
- [x] `NSPrivacyTracking = true` — AdMob ATT 대응
- [x] `Info.plist` 카메라/사진 라이브러리/ATT 권한 설명 완료
- [x] App Store Connect 웹 양식 입력 완료 — Privacy Labels 게시
  - Contact Info: Email Address, Name ✅
  - Health & Fitness: Health, Fitness ✅
  - User Content: Photos or Videos, Other User Content ✅
  - Identifiers: User ID (앱 기능), Device ID (추적 용도) ✅
  - Identifiers: 광고 데이터 (추적 용도) ✅
  - "Data Used to Track You" → **Yes** (AdMob ATT 대응) ✅
  - NSUserTrackingUsageDescription ↔ Privacy Labels 충돌 해소 ✅

---

## 🔴 높음(HIGH) — 출시 전 강력 권장

### H1. 백엔드 — application-prod.yml 강화 ✅ 완료
- [x] `server.tomcat.threads` 튜닝 (max: 200, min-spare: 20, accept-count: 100)
- [x] CORS 정책 prod 도메인 화이트리스트 고정 (`https://api.gainsy.site`)
- [x] Rate limiting (인메모리 토큰 버킷) — `/api/v1/auth/**` 분당 20회 제한, 429 응답
- [x] `spring.datasource.hikari.leak-detection-threshold: 60000` 설정
- [x] 로그 포맷 JSON 구조화 (CloudWatch 파싱용)

### H2. 백엔드 — AWS 운영 인프라 ⚠️ 부분 완료
- [x] Terraform Stage 1 완전 프로비저닝 — VPC, EC2, RDS, ElastiCache, ECR, S3, Route 53
- [x] S3 prod 버킷 실 AWS 전환 (`LocalStack` → 실 S3)
- [x] RDS 자동 백업 활성화 (보존 기간 7일, Terraform 확인), `deletion_protection = true`
- [x] S3 버킷 버전 관리 활성화 (Terraform 확인), SSE-S3 암호화 적용 중
- [x] CloudWatch 로그 그룹(`/healthcare/prod/app`) + 알람 (CPU, RDS storage/connections) 추가
- [ ] AWS Secrets Manager 또는 SSM Parameter Store로 환경변수 이관 (현재 GitHub Secrets)

### H3. iOS — 핵심 작성 플로우 UI 테스트
- ViewModel 단위 테스트 25개 완료, smoke UI 일부 있음
- [ ] 운동 기록 추가 → 저장 → 목록 반영 UI 테스트
- [ ] 식단 검색 → 직접 등록 폴백 → 저장 UI 테스트
- [ ] 신체 측정 입력 → 추세 그래프 반영 UI 테스트

### H4. iOS — 접근성 ⚠️ 부분 완료
- [x] Dynamic Type 전면 적용 (Typography 스케일 재구성)
- [x] VoiceOver 홈 대시보드 레이블·힌트·그룹 지정
- [x] 다크모드 전면 지원 (어댑티브 컬러 토큰, Forest 톤)
- [ ] VoiceOver 핵심 플로우 검증 (홈 → 기록 → 저장)
- [ ] 색 대비 WCAG AA 기본 충족 확인

### H5. iOS — 로딩/에러/빈 상태 일관성
- [ ] 모든 화면 빈 상태 문구/일러스트 통일 (`EmptyStateView` 공통화)
- [ ] 에러 시 토스트/Alert 톤 일관성
- [ ] 네트워크 오류 vs 인증 만료 vs 서버 에러 메시지 차등 처리

### H6. 백엔드 — Health Check + Readiness Probe ✅ 완료
- [x] Spring Boot Actuator `/actuator/health/readiness`, `/actuator/health/liveness` 구분 활성화
- [x] SecurityConfig에 readiness/liveness permitAll 추가
- [ ] ALB 미사용 (EC2 직접 Route 53 연결 구조), Target Group health check 해당 없음

---

## 🟡 중간(MEDIUM) — 출시 직후 또는 가능하면 정리

### M1. 진행 사진 UX 마무리
- [ ] 업로드 실패/부분 완료 재시도 UX
- [ ] 서버 썸네일 URL 분기 표시 (백엔드 EXIF 제거+썸네일 생성 완료)
- [ ] 촬영 시점 선택 + 메모 입력 UX

### M2. 신체측정 ↔ 목표 진행률 이동 흐름
- [ ] 목표 진행률 화면에서 측정 히스토리로 점프
- [ ] 빈 데이터 최초 기록 유도 UX

### M3. AI기본법 disclaimer iOS 표시 확인
- 백엔드 `isAiEstimated: true` + `disclaimer` 필드, iOS 배지/disclaimer 표시 구현 완료
- [ ] 실 디바이스에서 식단·운동 AI 추정 카드 표시 회귀 검증 1회

### M4. iOS — APNs 실기기 테스트
- [ ] APNs prod 환경 푸시 수신 확인 (Firebase 테스트 발송)
- [ ] `WEEKLY_SUMMARY` 라우팅 (탐색 탭 이동) 동작 확인
- [ ] FCM 토큰 PATCH `/api/v1/users/me` 정상 업로드 확인

### M5. CI/CD 마무리
- [x] `ci-backend.yml`, `ci-ios.yml`, `dev-to-prod.yml` 완료
- [ ] iOS CI에 `xcodebuild archive` + TestFlight 업로드 단계 추가 (fastlane, 선택)

### M6. 환경변수 체크리스트 문서화
- [ ] `docs/operations/ENV_CHECKLIST.md` — prod 배포 시 필요한 모든 시크릿 목록 및 설정 위치

---

## ⚖️ 법적/규제 점검

### L1. 비의료기기 분류 확인 ✅
- 식약처 지침 확인 완료 — 칼로리/식단 추적은 비의료기기

### L2. AI기본법(2026) 대응 ✅
- 응답에 `isAiEstimated: true` + `disclaimer` 포함 — 백엔드/iOS 양쪽 반영 완료

### L3. 개인정보보호법 — 필수 동의 항목 ✅ 완료
- [x] 회원가입 시 필수 동의 화면 — `SignUpView` 이용약관·개인정보처리방침 체크박스 추가, 미동의 시 가입 버튼 비활성화, 링크 탭 시 Safari 오픈
- [x] 만 14세 미만 가입 제한 — `AuthService.register()`에 `ChronoUnit.YEARS` 나이 검증 추가, `@Past` 유효성 검사 추가
- [x] `MyPageView` 앱 정보 섹션에 이용약관·개인정보처리방침 링크 추가
- [ ] 개인정보 처리방침에 위탁 처리(AWS, OpenAI, Firebase) 명시 확인 (문서 보강 권장)

### L4. 헬스데이터 — App Store 추가 요구사항
- [x] `NSHealthShareUsageDescription` (`ios/project.yml`) 설정 완료
- [ ] HealthKit 데이터 마케팅 활용 금지(App Review Guidelines 5.1.3) 준수 명시

### L5. 사진/카메라 접근 ✅
- `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` 명시 완료

---

## 📋 App Store Connect 등록 체크리스트

### 메타데이터
- [x] 앱 이름: **Gainsy** (CFBundleDisplayName 반영 완료)
- [x] 부제: `AI 기반 건강 기록 & 목표 관리` 입력 완료
- [x] 키워드 입력 완료 (헬스,다이어트,운동기록,식단관리 등)
- [x] 설명 입력 완료
- [x] 프로모션 텍스트 입력 완료
- [x] 카테고리: **건강 및 피트니스** (주), 라이프스타일 (부)
- [x] 연령 등급: **9+** (광고 포함, 건강/웰빙 주제)
- [x] 가격: 무료 (IAP 없음)

### 스크린샷
- [x] **6.7" iPhone** — 1320×2868 (iPhone 17 Pro Max), 5장 업로드 완료
  - 기록 메인 / 홈 대시보드 / 신체 변화 / 식단 기록 / 운동 기록
- [x] **13" iPad** — 2064×2752 또는 2048×2732 (심사 제출 필수 요건) ✅ 완료

### App Review 정보
- [x] 데모 계정 입력 완료
- [x] 리뷰 노트 입력 완료
- [x] 지원 URL: `https://kimgiii.github.io/health-care/docs/legal/privacy.html`
- [x] 저작권: `© 2026 KimGiii`

### 컴플라이언스
- [x] 수출 규정: `ITSAppUsesNonExemptEncryption: false` 설정 완료
- [x] AdMob 통합 — ATT 권한 요청, NSUserTrackingUsageDescription 설정 완료
- [x] Account Deletion: `DELETE /api/v1/users/me` + iOS MyPage 구현 완료

### 출시 옵션
- [x] 수동 출시 선택 완료
- [ ] TestFlight 외부 테스터 그룹 (5~10명) 모집

---

## 🔄 출시 직전 최종 회귀(Smoke) 시나리오

prod 환경에서 5~10명 테스터가 다음 시나리오를 완료해야 한다.

1. 회원가입 → 프로필 설정 → 목표 설정 → 홈 대시보드 확인
2. 운동 기록 추가(수동) → AI 추정 폴백 → 홈 반영
3. 식단 기록 추가 → 식품 검색 → 직접 등록 → 히스토리 확인
4. 신체 측정 입력 → 추세 그래프 확인
5. 진행 사진 촬영 → 업로드 → 비교 모드
6. 목표 진행 화면 → 주간 회고 → 변화 분석
7. 푸시 알림(주간 요약) 수신 → 탭 → 탐색 탭 이동
8. 마이페이지 → 프로필 수정 → 로그아웃 → 재로그인 → 토큰 refresh
9. 계정 삭제 → 데이터 정리 확인

**성능 기준**
- 기록 API < 500ms
- 검색 API < 300ms (캐시 히트)
- 사진 업로드 < 5초

---

## 📅 남은 작업 순서

**즉시 (이번 주)**
1. ~~dev → prod PR merge~~ ✅ 완료
2. ~~502 해소 확인~~ ✅ 완료 (200 응답 확인)
3. ~~B6 Privacy Labels 양식 작성~~ ✅ 완료
4. ~~App Store Connect 메타데이터 + 스크린샷 업로드~~ ✅ 완료
5. ~~App Review 정보·가격·연령 등급·카테고리 입력~~ ✅ 완료
6. ~~Privacy Labels 추적 충돌 해소~~ ✅ 완료 (Data Used to Track → Yes)
7. [x] **iPad 13" 스크린샷 업로드** ✅ 완료
8. [x] **Xcode Archive build 4 → TestFlight 업로드** ✅ 완료
9. [x] **심사 제출** ✅ 완료 (2026-05-15, 심사 대기 중)
10. [ ] TestFlight 외부 테스터 5~10명 초대

**출시 후**
11. H1 prod yml 강화, H6 Health Check
12. M1~M4 UX 보강
13. AWS Secrets Manager 이관 (선택)

---

## 핵심 파일 참조

| 파일 | 역할 |
|---|---|
| [ios/project.yml](../../ios/project.yml) | iOS 빌드 설정 (Team ID, ATS, Info.plist 키) |
| [ios/Configs/Release.xcconfig](../../ios/Configs/Release.xcconfig) | Release BASE_URL |
| [backend/src/main/resources/application-prod.yml](../../backend/src/main/resources/application-prod.yml) | prod 설정 |
| [infra/terraform/aws/](../../infra/terraform/aws) | AWS 인프라 정의 |
| [.github/workflows/dev-to-prod.yml](../../.github/workflows/dev-to-prod.yml) | prod 배포 파이프라인 |
| [docs/exec-plans/BACKEND_TODO.md](BACKEND_TODO.md) | 백엔드 잔여 작업 |
| [docs/exec-plans/IOS_TODO.md](IOS_TODO.md) | iOS 잔여 작업 |
| [docs/operations/DOMAIN_MIGRATION_GAINSY_SITE.md](../operations/DOMAIN_MIGRATION_GAINSY_SITE.md) | 도메인 전환 운영 가이드 |
