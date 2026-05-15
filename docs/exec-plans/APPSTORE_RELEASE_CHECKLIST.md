# App Store 출시 준비 체크리스트

**최종 업데이트**: 2026-05-15  
**현재 Phase 6 진행률**: 85%

## 상황 요약

Phase 0~5(인증/운동/식단/신체측정/진행사진/목표/인사이트) 모두 100% 완료. BLOCKER 6개 완료. App Store Connect 메타데이터(설명·키워드·스크린샷·앱 심사 정보) 입력 완료. TestFlight build 4(광고 포함) 업로드 → 심사 제출이 남아 있다.

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
  - Identifiers: User ID, Device ID ✅
  - "Data Used to Track You" → No ✅

---

## 🔴 높음(HIGH) — 출시 전 강력 권장

### H1. 백엔드 — application-prod.yml 강화
- **현황**: 최소 구성, Nginx X-Forwarded 헤더 신뢰 설정 완료
- **누락 항목**:
  - [ ] `server.tomcat.threads` 튜닝 (max-threads, accept-count)
  - [ ] CORS 정책 prod 도메인 화이트리스트 고정
  - [ ] Rate limiting (Bucket4j) — 인증 API 무차별 대입 방어
  - [ ] `spring.datasource.hikari.leak-detection-threshold` 설정
  - [ ] 로그 포맷 JSON 구조화 (CloudWatch 파싱용)

### H2. 백엔드 — AWS 운영 인프라 ⚠️ 부분 완료
- [x] Terraform Stage 1 완전 프로비저닝 — VPC, EC2, RDS, ElastiCache, ECR, S3, Route 53
- [x] S3 prod 버킷 실 AWS 전환 (`LocalStack` → 실 S3)
- [ ] RDS 자동 백업 활성화 (보존 기간 7일+)
- [ ] S3 버킷 서버 측 암호화(SSE-KMS) + 버전 관리 활성화
- [ ] CloudWatch 로그 그룹 생성 + 알람 (5xx 비율, CPU, RDS connection)
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

### H6. 백엔드 — Health Check + Readiness Probe
- [ ] Spring Boot Actuator `/actuator/health/readiness`, `/liveness` 구분 (DB·Redis·S3 포함)
- [ ] ALB Target Group health check 경로 적용

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

### L3. 개인정보보호법 — 필수 동의 항목
- [ ] 회원가입 시 필수 동의 화면 (이용약관, 개인정보 처리방침 링크 표시)
- [ ] 만 14세 미만 가입 제한 (`dateOfBirth` 기반 검증 여부 확인)
- [ ] 개인정보 처리방침에 위탁 처리(AWS, OpenAI, Firebase) 명시 확인

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
5. ~~App Review 정보 입력~~ ✅ 완료
6. [ ] **Xcode Archive build 4 → TestFlight 업로드** (광고 코드 복원 후 재빌드 필요)
7. [ ] **심사 제출** (build 4 선택 후 제출)
8. [ ] TestFlight 외부 테스터 5~10명 초대

**출시 후**
9. H1 prod yml 강화, H6 Health Check
10. M1~M4 UX 보강
11. AWS Secrets Manager 이관 (선택)

**출시 후**
10. H1 prod yml 강화, H6 Health Check
11. M1~M4 UX 보강
12. AWS Secrets Manager 이관 (선택)

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
