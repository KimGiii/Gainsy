# App Store Connect — Privacy Nutrition Labels 입력 가이드

**작성일**: 2026-05-15  
**대상**: App Store Connect → Apps → Gainsy → App Privacy

---

## 들어가기 전에

App Store Connect의 "App Privacy" 섹션에서 직접 입력해야 한다.  
`PrivacyInfo.xcprivacy`(코드 레벨)와 별개로, App Store Connect 웹 양식을 **수동으로 입력**해야 심사 통과가 된다.

경로: **App Store Connect → Apps → Gainsy → App Privacy → Get Started**

---

## 1단계: 데이터 수집 여부

> "Does this app collect data?" → **YES**

---

## 2단계: 수집하는 데이터 유형 선택

아래 항목을 **체크**한다.

| 카테고리 | 항목 | 체크 여부 |
|---------|------|---------|
| Contact Info | Email Address | ✅ |
| Contact Info | Name | ✅ |
| Health & Fitness | Health | ✅ |
| Health & Fitness | Fitness | ✅ |
| User Content | Photos or Videos | ✅ |
| User Content | Other User Content | ✅ |
| Identifiers | User ID | ✅ |
| Identifiers | Device ID | ✅ |

**체크하지 않는 항목** (수집 안 함):
- Location (정확한/대략적 위치 모두 없음)
- Financial Info
- Sensitive Info
- Contacts
- Browsing History / Search History
- Purchases
- Usage Data (광고/분석 SDK 없음)
- Diagnostics (Firebase Crashlytics 없음)

---

## 3단계: 항목별 세부 설정

각 데이터 유형마다 아래 세 가지를 입력한다:

### Contact Info › Email Address

| 항목 | 값 |
|------|---|
| Used for Tracking? | **No** |
| Linked to Identity? | **Yes** |
| Purpose | **App Functionality** |
| 설명 | 계정 생성, 로그인, 비밀번호 찾기에 사용 |

### Contact Info › Name

| 항목 | 값 |
|------|---|
| Used for Tracking? | **No** |
| Linked to Identity? | **Yes** |
| Purpose | **App Functionality** |
| 설명 | 앱 내 표시 닉네임(displayName)으로 사용. 실명 아님 |

### Health & Fitness › Health

| 항목 | 값 |
|------|---|
| Used for Tracking? | **No** |
| Linked to Identity? | **Yes** |
| Purpose | **App Functionality** |
| 설명 | 체중, 체지방률, 근육량, BMI, 신체 둘레(가슴/허리/엉덩이/허벅지/팔)를 서버에 저장하여 추세 그래프 및 목표 진행률 계산에 사용 |

### Health & Fitness › Fitness

| 항목 | 값 |
|------|---|
| Used for Tracking? | **No** |
| Linked to Identity? | **Yes** |
| Purpose | **App Functionality** |
| 설명 | 운동 세션(종류, 시간, 세트, 무게, MET값)을 서버에 저장하여 운동 기록 및 목표 진행률 계산에 사용 |

### User Content › Photos or Videos

| 항목 | 값 |
|------|---|
| Used for Tracking? | **No** |
| Linked to Identity? | **Yes** |
| Purpose | **App Functionality** |
| 설명 | 사용자가 직접 촬영하거나 선택한 진행 사진을 암호화된 AWS S3에 저장. 사용자 본인만 조회 가능 |

### User Content › Other User Content

| 항목 | 값 |
|------|---|
| Used for Tracking? | **No** |
| Linked to Identity? | **Yes** |
| Purpose | **App Functionality** |
| 설명 | 식단 기록(식품명, 섭취량, 칼로리), 커스텀 식품 등록, 운동 목표, 주간 메모 등을 서버에 저장 |

### Identifiers › User ID

| 항목 | 값 |
|------|---|
| Used for Tracking? | **No** |
| Linked to Identity? | **Yes** |
| Purpose | **App Functionality** |
| 설명 | 앱 서버에서 생성하는 내부 사용자 식별자(UUID). API 인증(JWT)에 사용. 광고 목적 없음 |

### Identifiers › Device ID

| 항목 | 값 |
|------|---|
| Used for Tracking? | **No** |
| Linked to Identity? | **Yes** |
| Purpose | **App Functionality** |
| 설명 | FCM(Firebase Cloud Messaging) 푸시 토큰. 주간 건강 요약 알림 발송에만 사용. 광고/추적 목적 없음 |

---

## 4단계: Data Used to Track You

> "Is any of the data used to track users across apps or websites?" → **No**

Firebase Analytics, 광고 SDK, IDFA 사용 없음.

---

## 5단계: Account Deletion

> "Does this app allow users to delete their account?" → **Yes**

- 구현 위치: 마이페이지 → 계정 삭제
- 백엔드 엔드포인트: `DELETE /api/v1/users/me`
- 삭제 시 처리: 사용자 계정 + 연관 데이터 모두 삭제 (soft-delete → 실 삭제 정책 확인)

---

## 6단계: 최종 확인 체크리스트

입력 완료 후 아래를 확인한다:

- [ ] "Data Not Collected" 항목이 없는지 (수집 항목이 모두 입력됐는지)
- [ ] "Data Used to Track You" → No 선택 확인
- [ ] Account Deletion → Yes 선택 확인
- [ ] 모든 항목에 Purpose(App Functionality) 선택 확인
- [ ] Save 후 "App Privacy" 페이지에 Privacy Nutrition Label 미리보기가 올바르게 나타나는지 확인

---

## 참고: PrivacyInfo.xcprivacy vs App Store Connect 대응표

| PrivacyInfo.xcprivacy 키 | App Store Connect 항목 |
|---|---|
| `NSPrivacyCollectedDataTypeEmailAddress` | Contact Info > Email Address |
| `NSPrivacyCollectedDataTypeName` | Contact Info > Name |
| `NSPrivacyCollectedDataTypeHealth` | Health & Fitness > Health |
| `NSPrivacyCollectedDataTypePhysicalActivityAndSports` | Health & Fitness > Fitness |
| `NSPrivacyCollectedDataTypePhotosOrVideos` | User Content > Photos or Videos |
| `NSPrivacyCollectedDataTypeOtherUserContent` | User Content > Other User Content |
| `NSPrivacyCollectedDataTypeUserID` | Identifiers > User ID |
| `NSPrivacyCollectedDataTypeDeviceID` | Identifiers > Device ID |

---

## 주의사항

- App Store Connect 입력은 앱 업데이트 심사와 별개로 즉시 반영 가능하다.
- 한 번 제출한 후 데이터 수집 항목이 변경되면 반드시 업데이트해야 심사 거부를 피할 수 있다.
- HealthKit 데이터를 실제로 읽거나 쓰는 경우 "Health & Fitness > Health" 항목의 사용 목적이 `NSHealthShareUsageDescription`/`NSHealthUpdateUsageDescription`과 일치해야 한다.
