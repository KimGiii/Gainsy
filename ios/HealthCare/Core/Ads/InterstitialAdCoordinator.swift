import GoogleMobileAds
import UIKit

@MainActor
final class InterstitialAdCoordinator: NSObject {
    private var interstitial: GADInterstitialAd?
    private let adUnitID: String

    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        loadAd()
    }

    func showIfReady() {
        guard
            let rootVC = UIApplication.shared
                .connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })?
                .windows
                .first(where: \.isKeyWindow)?
                .rootViewController,
            let ad = interstitial
        else { return }
        ad.present(fromRootViewController: rootVC)
    }

    private func loadAd() {
        Task {
            do {
                let ad = try await GADInterstitialAd.load(
                    withAdUnitID: adUnitID,
                    request: GADRequest()
                )
                self.interstitial = ad
                self.interstitial?.fullScreenContentDelegate = self
            } catch {
                print("[AdMob] 전면 광고 로드 실패: \(error.localizedDescription)")
            }
        }
    }
}

extension InterstitialAdCoordinator: @preconcurrency GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        interstitial = nil
        loadAd()
    }

    func ad(
        _ ad: GADFullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("[AdMob] 전면 광고 표시 실패: \(error.localizedDescription)")
        interstitial = nil
        loadAd()
    }
}
