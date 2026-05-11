import SwiftUI

// MARK: - ActivityRingPanel
//
// 홈 대시보드 최상단 핵심 위젯.
// 왼쪽 큰 칼로리 링(hero) + 오른쪽 운동/단백질 링(standard) + 하단 매크로 스트립.
// 라이트 본(bone) 배경 위에서 명도 대비를 확보해 가독성을 높인다.

struct ActivityRingPanel: View {
    let calorieProgress: Double
    let activityProgress: Double
    let proteinProgress: Double

    let todayCalories: Double
    let dailyCalorieGoal: Double
    let todayDurationMinutes: Int
    let todayBurnedCalories: Double
    let todayProteinG: Double
    let dailyProteinGoal: Double

    var body: some View {
        VStack(spacing: 0) {
            // 링 영역
            HStack(alignment: .center, spacing: 20) {
                // 왼쪽 — 칼로리 (hero)
                ProgressRing(
                    progress: calorieProgress,
                    gradient: .ringCalorie,
                    size: .hero,
                    value: caloriesValueText,
                    unit: "kcal",
                    label: "칼로리 섭취",
                    trackColor: Color.brandDusk.opacity(0.10)
                )

                // 오른쪽 — 운동 + 단백질 (standard × 2)
                VStack(spacing: 16) {
                    ProgressRing(
                        progress: activityProgress,
                        gradient: .ringActivity,
                        size: .standard,
                        value: "\(todayDurationMinutes)",
                        unit: "min",
                        label: "운동",
                        trackColor: Color.brandDusk.opacity(0.10)
                    )

                    ProgressRing(
                        progress: proteinProgress,
                        gradient: LinearGradient(
                            colors: [Color.brandAccentGlow, Color.brandAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        size: .standard,
                        value: String(format: "%.0f", todayProteinG),
                        unit: "g",
                        label: "단백질",
                        trackColor: Color.brandDusk.opacity(0.10)
                    )
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()
                .background(Color.brandDusk.opacity(0.07))
                .padding(.horizontal, 20)

            // 하단 — 소모 칼로리 + 목표 대비 요약
            HStack {
                summaryChip(
                    icon: "flame.fill",
                    color: Color.brandEmber,
                    value: String(format: "%.0f", todayBurnedCalories),
                    unit: "kcal 소모"
                )
                Spacer()
                summaryChip(
                    icon: "target",
                    color: Color.brandAccent,
                    value: String(format: "%.0f", dailyCalorieGoal - todayCalories),
                    unit: "kcal 남음"
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.brandDusk.opacity(0.06), lineWidth: 1)
                )
        )
        .elevation(.low)
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private var caloriesValueText: String {
        let v = Int(todayCalories)
        if v >= 1_000 {
            // "1,420" 형식
            return String(format: "%d,%03d", v / 1_000, v % 1_000)
        }
        return "\(v)"
    }

    @ViewBuilder
    private func summaryChip(icon: String, color: Color, value: String, unit: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.brandBone.ignoresSafeArea()
        ActivityRingPanel(
            calorieProgress: 0.71,
            activityProgress: 0.75,
            proteinProgress: 0.65,
            todayCalories: 1_420,
            dailyCalorieGoal: 2_000,
            todayDurationMinutes: 45,
            todayBurnedCalories: 320,
            todayProteinG: 98,
            dailyProteinGoal: 150
        )
        .padding(.vertical, 40)
    }
}
