import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var authState: AuthState

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Background ──────────────────────────────────────
                Color.backgroundPage.ignoresSafeArea()

                // ── Decorative blobs ─────────────────────────────────
                Circle()
                    .fill(Color.surfaceCard)
                    .frame(width: 320, height: 320)
                    .blur(radius: 2)
                    .offset(x: -80, y: -260)

                Circle()
                    .fill(Color.surfaceCard.opacity(0.6))
                    .frame(width: 200, height: 200)
                    .offset(x: 130, y: 200)

                // ── Content ──────────────────────────────────────────
                VStack(spacing: 0) {
                    Spacer()

                    // Logo
                    BrandLogoView(size: 160, color: Color.brandPrimary)
                        .padding(.bottom, 36) // design-lint:ignore — micro/hero spacing

                    // Copy
                    VStack(spacing: 10) {
                        Text("Gainsy")
                            .font(.brandWordmark)
                            .foregroundStyle(Color.brandPrimary)

                        Text("운동·식단·신체변화를 하나로\n매일 기록하고 꾸준히 성장하세요")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    Spacer()

                    // CTA Buttons
                    VStack(spacing: 12) {
                        NavigationLink(destination: LoginView()) {
                            PrimaryButtonLabel(title: "로그인하기")
                        }

                        NavigationLink(destination: SignUpView()) {
                            SecondaryButtonLabel(title: "계정이 없어요, 가입하기")
                        }
                    }
                    .padding(.horizontal, Spacing.xxl) // design-lint:ignore — micro/hero spacing
                    .padding(.bottom, 48) // design-lint:ignore — micro/hero spacing
                }
            }
        }
    }
}
