import SwiftUI

// MARK: - MacroBreakdownCard
//
// 단백질 / 탄수화물 / 지방 섭취 진행 현황을 한눈에 보여주는 카드.
// 각 매크로는 아이콘 + 진행 바 + g수/목표 텍스트로 구성된다.

struct MacroBreakdownCard: View {
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 헤더
            HStack {
                Text("MACROS")
                    .eyebrowStyle()
                Spacer()
                Text("오늘 섭취")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 10) {
                MacroRow(
                    label: "단백질",
                    current: proteinG,
                    goal: proteinGoal,
                    color: Color.brandAccent,
                    unit: "g"
                )
                MacroRow(
                    label: "탄수화물",
                    current: carbsG,
                    goal: carbsGoal,
                    color: Color.brandSunrise,
                    unit: "g"
                )
                MacroRow(
                    label: "지방",
                    current: fatG,
                    goal: fatGoal,
                    color: Color.brandEmber,
                    unit: "g"
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.cardStroke, lineWidth: 1)
                )
        )
        .elevation(.low)
    }
}

// MARK: - MacroRow

private struct MacroRow: View {
    let label: String
    let current: Double
    let goal: Double
    let color: Color
    let unit: String

    private var progress: Double { min(current / max(goal, 1), 1.0) }

    var body: some View {
        VStack(spacing: 5) {
            HStack(alignment: .lastTextBaseline) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", current))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text("/ \(Int(goal))\(unit)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
            }

            // 진행 바
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 트랙
                    Capsule()
                        .fill(color.opacity(0.12))
                        .frame(height: 6)

                    // 진행
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.spring(response: 0.8, dampingFraction: 0.82), value: progress)
                }
            }
            .frame(height: 6)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(String(format: "%.0f", current))\(unit) / \(Int(goal))\(unit)")
    }
}

#Preview {
    ZStack {
        Color.brandBone.ignoresSafeArea()
        MacroBreakdownCard(
            proteinG: 98,
            carbsG: 165,
            fatG: 42,
            proteinGoal: 150,
            carbsGoal: 200,
            fatGoal: 60
        )
        .padding(20)
    }
}
