import SwiftUI
import Charts

// MARK: - WeeklyTrendCard
//
// 최근 7일 칼로리 섭취 추세를 바 차트로 보여주는 카드.
// Swift Charts (iOS 16+) 사용.

struct WeeklyTrendCard: View {
    let weeklyActivity: [DayActivity]

    @State private var selectedDay: DayActivity? = nil

    private var maxCalories: Double {
        max(weeklyActivity.map(\.caloriesIn).max() ?? 0, 500)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 헤더
            HStack {
                Text("WEEKLY")
                    .eyebrowStyle()
                Spacer()
                if let sel = selectedDay {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(String(format: "%.0f", sel.caloriesIn))
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.brandPrimary)
                        Text("kcal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .transition(.opacity)
                } else {
                    Text("7일 섭취 추세")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
            }

            // 바 차트
            Chart(weeklyActivity, id: \.date) { day in
                BarMark(
                    x: .value("날짜", shortLabel(day.date)),
                    y: .value("칼로리", day.caloriesIn)
                )
                .foregroundStyle(
                    day.date == selectedDay?.date
                        ? Color.brandPrimary
                        : Color.brandAccent.opacity(day.caloriesIn > 0 ? 0.75 : 0.18)
                )
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...maxCalories * 1.2)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 90)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { val in
                                    guard let date: String = proxy.value(atX: val.location.x) else { return }
                                    selectedDay = weeklyActivity.first { shortLabel($0.date) == date }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.3)) { selectedDay = nil }
                                }
                        )
                }
            }

            // 운동 소모 요약 줄
            let totalBurned = weeklyActivity.map(\.caloriesBurned).reduce(0, +)
            if totalBurned > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.brandEmber)
                    Text("이번 주 \(Int(totalBurned)) kcal 소모")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
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
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func shortLabel(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3, let day = Int(parts[2]) else { return dateStr }
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateStr) {
            let idx = Calendar.current.component(.weekday, from: date) - 1
            return weekdays[idx]
        }
        return "\(day)"
    }
}

#Preview {
    ZStack {
        Color.brandBone.ignoresSafeArea()
        let activities = [
            DayActivity(date: "2026-05-02", caloriesIn: 1850, caloriesBurned: 280, durationMinutes: 40),
            DayActivity(date: "2026-05-03", caloriesIn: 1600, caloriesBurned: 0,   durationMinutes: 0),
            DayActivity(date: "2026-05-04", caloriesIn: 1920, caloriesBurned: 350, durationMinutes: 50),
            DayActivity(date: "2026-05-05", caloriesIn: 1400, caloriesBurned: 200, durationMinutes: 30),
            DayActivity(date: "2026-05-06", caloriesIn: 2100, caloriesBurned: 420, durationMinutes: 60),
            DayActivity(date: "2026-05-07", caloriesIn: 1750, caloriesBurned: 310, durationMinutes: 45),
            DayActivity(date: "2026-05-08", caloriesIn: 900,  caloriesBurned: 320, durationMinutes: 42),
        ]
        WeeklyTrendCard(weeklyActivity: activities)
            .padding(.vertical, 40)
    }
}
