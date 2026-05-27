# App Store 재심사 거절 대응 — 2026-05-19 (3건)

> Submission ID: a5176114-63d2-4799-b5aa-dc8a716bd4d9
> Review date: 2026-05-19
> Review device: iPhone 17 Pro Max (iOS 26.5)
> Version reviewed: 1.0 (6)
> 대응 PR: [Gainsy#22](https://github.com/KimGiii/Gainsy/pull/22) (dev → prod)
> 대응 완료일: 2026-05-20

## 1. 거절 개요

2026-05-15 거절([APPSTORE_REVIEW_REJECTION_2026_05_15.md](APPSTORE_REVIEW_REJECTION_2026_05_15.md))은 백엔드 502 회복으로 해소했으나, 재제출 후 추가 거절 3건을 받음.

| # | Guideline | 요지 |
|---|---|---|
| ① | **1.4.1** Safety — Physical Harm | 의학·건강 정보(BMI 계산·영양 정보)에 출처(citation) 없음 |
| ② | **2.5.1** Performance — Software Requirements | HealthKit/CareKit API 사용 표시는 있는데 UI에서 명시적으로 식별되지 않음 |
| ③ | **2.1** Information Needed | iOS 26.5에서 ATT 권한 프롬프트가 보이지 않음. 동영상 증빙 요청 |

## 2. 원인 분석

### 2.1. ① 1.4.1 — 의학 정보 출처 누락

- BMI 자동 계산 화면([AddMeasurementView.swift](../../ios/HealthCare/Features/Record/BodyMeasurement/Views/AddMeasurementView.swift))에서 BMI 값을 표시하지만, 계산식이나 분류 기준의 출처를 표시하지 않음.
- 식단 상세 화면([DietLogDetailView.swift](../../ios/HealthCare/Features/Record/Diet/Views/DietLogDetailView.swift))의 칼로리·단백질·탄수화물·지방 수치가 어떤 데이터베이스를 근거로 하는지 명시 없음.
- Apple은 의학 정보 앱에 대해 사용자가 출처를 쉽게 확인할 수 있는 형태의 인용(링크 등)을 요구.

### 2.2. ② 2.5.1 — HealthKit 식별 누락

- `ios/HealthCare/Resources/Info.plist`·`ios/project.yml`에 `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` 키 선언됨.
- 그러나 실제 Swift 코드 전체에 `import HealthKit`·`HKHealthStore`·`HKQuantity` 등 사용 흔적 **0건**.
- 결과: Apple은 plist 선언만으로 "HealthKit 사용 중인데 UI에 표시가 없다"고 판단.
- 진단: 키만 남아 있고 실제 통합이 없음. 가장 단순한 해결책은 **키 제거**.

### 2.3. ③ 2.1 — ATT 프롬프트 미발견

- 기존 구현: [AppDelegate.swift](../../ios/HealthCare/App/AppDelegate.swift)의 `applicationDidBecomeActive(_:)`에서 `ATTrackingManager.requestTrackingAuthorization()` 호출.
- 문제:
  1. `applicationDidBecomeActive`는 앱 첫 진입 시 윈도우·씬 준비 직후 너무 이른 시점에 호출됨. 일부 iOS 버전에서 이 시점의 시스템 다이얼로그는 즉시 dismiss되거나 표시 자체가 거부될 수 있음.
  2. `configurePushNotifications`의 푸시 권한 요청과 거의 동시에 트리거되어 ATT 프롬프트가 가려질 가능성.
  3. App Tracking Transparency 가이드라인은 "데이터 수집 직전, 사용자에게 맥락이 충분히 전달된 후" 요청할 것을 요구.

## 3. 조치 내역

### 3.1. ① 의학 정보 출처

신규 출처/면책 통합 화면 추가: [MedicalSourcesView.swift](../../ios/HealthCare/Features/Info/MedicalSourcesView.swift)

수록 출처:
- **BMI 계산식**: WHO – Body mass index, WHO – Obesity and overweight
- **BMI 분류 기준**: WHO 국제 기준 + 대한비만학회 진료지침 (국가 기준 병기)
- **영양 성분 데이터**: 식약처 식품영양성분 DB, USDA FoodData Central
- **운동 권장량**: WHO Physical activity guidelines
- **의료 면책 고지**: 진단·치료·처방 대체 아님 명시

접근 경로 4곳에 출처 진입점 노출:

| 위치 | 진입 UI |
|---|---|
| [AddMeasurementView.swift](../../ios/HealthCare/Features/Record/BodyMeasurement/Views/AddMeasurementView.swift) | BMI 입력 영역 아래 "BMI 계산식 및 분류 기준 출처 보기 (WHO·대한비만학회)" 푸터 |
| [BodyMeasurementView.swift](../../ios/HealthCare/Features/Record/BodyMeasurement/Views/BodyMeasurementView.swift) | 최근 측정 카드의 BMI 셀 아래 "BMI 분류 기준: WHO·대한비만학회 출처 보기" 링크 |
| [DietLogDetailView.swift](../../ios/HealthCare/Features/Record/Diet/Views/DietLogDetailView.swift) | 영양 정보 카드 우측 ⓘ 아이콘 + 카드 하단 "출처: 식약처 식품영양성분 DB · USDA FoodData Central" 링크 |
| [MyPageView.swift](../../ios/HealthCare/Features/MyPage/Views/MyPageView.swift) | 앱 정보 메뉴 "의학 정보 출처" 항목 |

### 3.2. ② HealthKit 식별

[ios/project.yml](../../ios/project.yml)·[ios/HealthCare/Resources/Info.plist](../../ios/HealthCare/Resources/Info.plist)에서 두 키 제거.

```diff
- NSHealthShareUsageDescription
- NSHealthUpdateUsageDescription
```

이로써 plist상 HealthKit·CareKit 의존 선언이 사라져 2.5.1 위반 사유가 제거됨. 향후 HealthKit 실 통합 시에는 키 재추가 + 실제 코드 통합 + UI 식별을 함께 진행해야 함.

### 3.3. ③ ATT 호출 흐름 재설계

- [AppDelegate.swift](../../ios/HealthCare/App/AppDelegate.swift): `applicationDidBecomeActive` 내 ATT 호출 제거, `import AppTrackingTransparency` 제거.
- 신규 사전 설명 화면: [TrackingPermissionView.swift](../../ios/HealthCare/Features/Tracking/TrackingPermissionView.swift)
  - 사용 목적·수집 정보·변경 방법 3개 항목 명시
  - 사용자가 "계속" 탭하는 순간에만 `ATTrackingManager.requestTrackingAuthorization()` 호출
- [RootView.swift](../../ios/HealthCare/Navigation/RootView.swift): 스플래시(2초) 종료 후 0.6초 추가 지연 → `ATTrackingManager.trackingAuthorizationStatus == .notDetermined`일 때만 `fullScreenCover`로 노출.
- UI 테스트 인자(`UI_TEST_RESET_STATE`, `UI_TEST_AUTHENTICATED`)일 땐 표시 생략.

## 4. 검증

- `xcodegen generate` 후 `xcodebuild ... -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" build` → `** BUILD SUCCEEDED **`.

## 5. App Store Connect 재회신 시 첨부 사항

거절 ③(2.1)이 명시적으로 요구한 실기기 화면 녹화 첨부 필요.

1. 신규 설치(혹은 시뮬레이터의 "Reset Location & Privacy" 후 실기기 동기화) 상태에서 앱 실행
2. 스플래시 종료
3. `TrackingPermissionView` 사전 설명 화면 표시
4. "계속" 탭 → 시스템 ATT 프롬프트 노출
5. "허용/허용 안 함" 선택 후 후속 화면(온보딩) 전환

녹화 파일을 App Store Connect > App Review Information > Notes 필드에 첨부.

## 6. 향후 재발 방지

- Info.plist 권한 키는 **실제 사용 코드와 1:1 매칭**되어야 한다. plist 수정 시 호출 코드 존재 여부 grep 필수.
- ATT 호출은 `applicationDidBecomeActive` 같은 라이프사이클 콜백이 아닌, **사용자 행동(예: 사전 설명 화면의 명시적 계속 버튼)** 직후에 한정.
- 의학·건강 정보를 새로 노출하는 화면을 만들 때는 화면 어딘가에 출처 진입 UI를 동시에 배치하는 규칙.
