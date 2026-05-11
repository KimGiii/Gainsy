import SwiftUI

// MARK: - QuickLogFAB
//
// 우측 하단 플로팅 액션 버튼.
// 기존 LogCTASection(전면 카드)을 대체해 기록 진입점을 FAB으로 강등.

struct QuickLogFAB: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            // 확장 메뉴 (위쪽)
            if isExpanded {
                VStack(alignment: .trailing, spacing: 10) {
                    FABMenuItem(
                        label: "식단 기록",
                        icon: "fork.knife",
                        destination: AnyView(DietRecordView())
                    )
                    FABMenuItem(
                        label: "운동 기록",
                        icon: "dumbbell.fill",
                        destination: AnyView(ExerciseRecordView())
                    )
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            // 메인 버튼
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient.sunrise)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.brandEmber.opacity(0.45), radius: 14, x: 0, y: 6)

                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                }
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - FABMenuItem

private struct FABMenuItem: View {
    let label: String
    let icon: String
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textHeadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color.surfaceCard)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                    )

                ZStack {
                    Circle()
                        .fill(Color.brandDusk)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.brandAccentGlow)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color.brandBone.ignoresSafeArea()
        QuickLogFAB()
    }
}
