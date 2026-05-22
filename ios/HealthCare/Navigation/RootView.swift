import AppTrackingTransparency
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authState: AuthState
    @State private var showSplash = true
    @State private var showTrackingPermission = false

    var body: some View {
        ZStack {
            Group {
                if ProcessInfo.processInfo.arguments.contains("UI_TEST_LOGIN_SCREEN") {
                    LoginView()
                } else {
                    switch authState.status {
                    case .unauthenticated:
                        OnboardingView()
                    case .profileSetup:
                        ProfileSetupView()
                    case .authenticated:
                        MainTabView()
                    case .loading:
                        Color(hex: "#F5F4EC").ignoresSafeArea()
                    }
                }
            }

            if showSplash {
                SplashView()
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal:   .opacity.combined(with: .scale(scale: 1.05))
                        )
                    )
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: showSplash)
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(2.0))
                showSplash = false
                try? await Task.sleep(for: .milliseconds(600))
                if ATTrackingManager.trackingAuthorizationStatus == .notDetermined,
                   !ProcessInfo.processInfo.arguments.contains("UI_TEST_RESET_STATE"),
                   !ProcessInfo.processInfo.arguments.contains("UI_TEST_AUTHENTICATED") {
                    showTrackingPermission = true
                }
            }
        }
        .fullScreenCover(isPresented: $showTrackingPermission) {
            TrackingPermissionView {
                showTrackingPermission = false
            }
        }
    }
}
