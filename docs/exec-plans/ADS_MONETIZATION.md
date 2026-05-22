# 광고 수익화 전략 및 구현 가이드

> 작성일: 2026-05-15  
> 상태: 구현 완료 (SDK 연동 대기 중)

---

## 1. 수익화 모델

### 티어 구조

| 티어 | 광고 노출 | 기능 범위 |
|------|-----------|-----------|
| **Free** | 배너 + 전면 광고 | 모든 기본 기능 |
| **Premium** (2단계) | 광고 없음 | 기본 기능 + AI 분석 무제한 |

> Premium 구독은 2단계 작업. 현재 스코프는 **광고 삽입**만.

---

## 2. 광고 위치 전략

### 2-1. 배너 광고 (Banner Ad)

| 항목 | 내용 |
|------|------|
| 위치 | `HomeView` 하단, `ExploreView` 하단 |
| 노출 방식 | 상시 노출 (`.safeAreaInset(edge: .bottom)`) |
| 크기 | `GADAdSizeBanner` (320×50) |
| 이유 | 체류 시간이 가장 긴 화면, 콘텐츠 방해 최소화 |

### 2-2. 전면 광고 (Interstitial Ad)

| 항목 | 내용 |
|------|------|
| 위치 | 식단 로그 저장 후, 운동 세션 저장 후 |
| 타이밍 | dismiss 완료 0.4초 후 (전환 애니메이션 종료 후) |
| 빈도 제한 | 세션 내 최대 1회, 30분 쿨다운 |
| 이유 | 자연스러운 화면 전환 타이밍, 입력 흐름 방해 없음 |

### 2-3. 광고 금지 구역

- `AddDietLogView`, `AddExerciseSessionView` — 입력 중 집중 방해
- `Onboarding`, `ProfileSetup` — 첫 경험 훼손
- `LoginView`, `SignupView`

---

## 3. SDK 및 기술 스택

- **SDK**: Google AdMob (`google-mobile-ads` SPM)
- **패키지 URL**: `https://github.com/googleads/swift-package-manager-google-mobile-ads`
- **최소 버전**: `11.0.0`
- **선택 이유**: 헬스 카테고리 fill rate 최고, Firebase 이미 통합됨

---

## 4. 구현 파일 목록

### 신규 생성

| 파일 | 역할 |
|------|------|
| `ios/HealthCare/Core/Ads/AdsManager.swift` | 광고 단위 ID 관리, 전면 광고 30분 쿨다운 |
| `ios/HealthCare/Core/Ads/BannerAdView.swift` | UIViewRepresentable GADBannerView 래퍼 |
| `ios/HealthCare/Core/Ads/InterstitialAdCoordinator.swift` | 전면 광고 프리로드 + 표시, 종료 후 자동 재로드 |

### 수정

| 파일 | 변경 내용 |
|------|-----------|
| `ios/project.yml` | GoogleMobileAds SPM 패키지 + 타겟 의존성 추가 |
| `ios/HealthCare/App/AppDelegate.swift` | `GADMobileAds.sharedInstance().start()` + ATT 권한 요청 |
| `ios/HealthCare/Features/Home/Views/HomeView.swift` | 하단 배너 삽입 |
| `ios/HealthCare/Features/Explore/Views/ExploreView.swift` | 하단 배너 삽입 |
| `ios/HealthCare/Features/Record/Diet/Views/AddDietLogView.swift` | 저장 후 전면 광고 트리거 |
| `ios/HealthCare/Features/Record/Exercise/Views/AddExerciseSessionView.swift` | 저장 후 전면 광고 트리거 |
| `ios/HealthCare/Resources/Info.plist` | `GADApplicationIdentifier`, `NSUserTrackingUsageDescription` 추가 |
| `ios/HealthCare/Resources/PrivacyInfo.xcprivacy` | 광고 데이터 수집 타입, `NSPrivacyTracking: true` |

---

## 5. 핵심 코드 패턴

### AdsManager (싱글톤)

```swift
// 전면 광고 표시 (쿨다운 자동 체크)
AdsManager.shared.showInterstitialIfReady()

// 배너 광고 단위 ID 참조
AdsManager.shared.bannerAdUnitID
```

### 배너 삽입 패턴

```swift
ScrollView { ... }
    .safeAreaInset(edge: .bottom) {
        BannerAdView(adUnitID: AdsManager.shared.bannerAdUnitID)
            .frame(height: 50)
    }
```

### 전면 광고 트리거 패턴 (저장 후)

```swift
await viewModel.save(apiClient: container.apiClient) {
    onSaved()
    Task { @MainActor in
        try? await Task.sleep(for: .seconds(0.4)) // 전환 애니메이션 대기
        AdsManager.shared.showInterstitialIfReady()
    }
}
```

---

## 6. 앱스토어 심사 대응

### ATT (App Tracking Transparency)

- `AppDelegate.applicationDidBecomeActive`에서 최초 1회 권한 요청
- 거부 시: AdMob이 자동으로 비개인화 광고 전환
- `NSUserTrackingUsageDescription` Info.plist에 등록 완료

### Privacy Manifest

- `NSPrivacyTracking: true` — ATT 동의 시 광고 추적 발생
- `NSPrivacyAccessedAPICategoryDiskSpace` — AdMob SDK 요구 사항
- `NSPrivacyCollectedDataTypeAdvertisingData` — 광고 데이터 수집 선언

---

## 7. AdMob 콘솔 설정 체크리스트

실제 배포 전 완료해야 할 작업:

- [ ] AdMob 콘솔에서 앱 등록 (Bundle ID: `com.kingloo.gainsy.ios`)
- [x] 앱 ID 발급 → `Info.plist`와 `project.yml`의 `GADApplicationIdentifier` 교체
  - 적용된 앱 ID: `ca-app-pub-6600084915621974~8422643430`
- [x] 배너 광고 단위 생성 → `ca-app-pub-6600084915621974/3457862451`
- [x] 전면 광고 단위 생성 → `ca-app-pub-6600084915621974/5892454105`
- [ ] `xcodegen generate` 실행 (프로젝트에 SPM 패키지 반영)
- [ ] 테스트 디바이스 등록 (실기기에서 테스트 광고 ID 확인)
- [ ] GDPR 대응 검토 (EU 사용자 대상 시 UMP SDK 추가 필요)

---

## 8. 테스트 방법

### 테스트 광고 단위 ID (DEBUG 빌드 자동 적용)

| 유형 | 테스트 ID |
|------|-----------|
| 배너 | `ca-app-pub-3940256099942544/2934735716` |
| 전면 | `ca-app-pub-3940256099942544/4411468910` |

### 검증 시나리오

1. **배너 노출**: HomeView, ExploreView 하단에 배너 광고 표시 확인
2. **전면 광고 타이밍**: 식단/운동 저장 후 0.4초 뒤 전면 광고 등장 확인
3. **쿨다운**: 저장 2회 연속 시 두 번째 전면 광고 미노출 확인
4. **금지 구역**: 입력 화면(`AddDietLogView`)에서 광고 미노출 확인
5. **ATT 흐름**: 최초 실행 후 앱이 Active 상태가 되면 권한 다이얼로그 표시 확인

---

## 9. 향후 로드맵

### Phase 2: Premium 구독 (예정)

- StoreKit 2 기반 월/연 구독 구현
- `AdsManager`에 `isPremium` 플래그 추가 → 배너·전면 광고 분기
- 구독 상태 백엔드 검증 (receipt validation)

### Phase 3: 광고 최적화 (예정)

- AdMob Mediation 설정 (Meta Audience Network, AppLovin 등 추가)
- 광고 수익 분석 → eCPM 기준 위치별 효율 측정
- ExploreView 피드 내 네이티브 광고 추가 검토
