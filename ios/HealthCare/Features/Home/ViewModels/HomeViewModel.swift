import Foundation

protocol HomeDashboardLoading: Sendable {
    func loadDietLogs(from: String, to: String) async throws -> DietLogListResponse
    func loadExerciseSessions() async throws -> SessionListResponse
    func loadGoals() async throws -> GoalListResponse
    func loadGoalProgress(id: Int) async throws -> GoalProgressResponse
}

extension APIClient: HomeDashboardLoading {
    func loadDietLogs(from: String, to: String) async throws -> DietLogListResponse {
        // size 50: 7일 × 4끼 = 최대 28개, 여유분 포함
        try await request(.getDietLogs(from: from, to: to, page: 0, size: 50))
    }
    func loadExerciseSessions() async throws -> SessionListResponse {
        // size 30: 7일치 세션을 충분히 커버
        try await request(.getExerciseSessions(from: nil, to: nil, page: 0, size: 30))
    }
    func loadGoals() async throws -> GoalListResponse {
        try await request(.getGoals)
    }
    func loadGoalProgress(id: Int) async throws -> GoalProgressResponse {
        try await request(.getGoalProgress(id: id))
    }
}

// MARK: - 주간 활동 데이터 포인트

struct DayActivity: Equatable {
    /// "yyyy-MM-dd" 형식 날짜
    let date: String
    /// 해당 날 총 섭취 칼로리
    let caloriesIn: Double
    /// 해당 날 운동 소모 칼로리
    let caloriesBurned: Double
    /// 해당 날 운동 시간 (분)
    let durationMinutes: Int
}

// MARK: - ViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    /// 오늘 식단 로그 (todayDietLogs 직접 설정은 테스트 전용)
    @Published var todayDietLogs: [DietLogSummary] = []
    /// 최근 7일 식단 로그 전체 (streak, 주간 추세 계산용)
    @Published var weekDietLogs: [DietLogSummary] = []
    @Published var recentSessions: [SessionSummary] = []
    @Published var activeGoal: GoalSummary? = nil

    // MARK: - 날짜 유틸리티

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    var today: String { dateFormatter.string(from: Date()) }

    private var weekStart: String {
        let date = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
        return dateFormatter.string(from: date)
    }

    // MARK: - 칼로리

    /// 오늘 총 섭취 칼로리
    var todayCalories: Double {
        todayDietLogs.compactMap(\.totalCalories).reduce(0, +)
    }

    /// 칼로리 일일 목표 (기본 2,000 kcal)
    var dailyCalorieGoal: Double { 2_000.0 }

    /// 칼로리 진행률 (0~1, 초과 시 1로 클램프)
    var calorieProgress: Double {
        min(todayCalories / dailyCalorieGoal, 1.0)
    }

    // MARK: - 운동 (오늘)

    /// 오늘 운동으로 소모한 총 칼로리
    var todayBurnedCalories: Double {
        recentSessions
            .filter { $0.sessionDate == today }
            .compactMap(\.caloriesBurned)
            .reduce(0, +)
    }

    /// 오늘 총 운동 시간 (분)
    var todayDurationMinutes: Int {
        recentSessions
            .filter { $0.sessionDate == today }
            .compactMap(\.durationMinutes)
            .reduce(0, +)
    }

    /// 운동 소모 칼로리 → 500 kcal 기준 활동 진행률 (0~1)
    var activityProgress: Double {
        min(todayBurnedCalories / 500.0, 1.0)
    }

    // MARK: - 매크로 (오늘)

    var todayProteinG: Double {
        todayDietLogs.compactMap(\.totalProteinG).reduce(0, +)
    }

    var todayCarbsG: Double {
        todayDietLogs.compactMap(\.totalCarbsG).reduce(0, +)
    }

    var todayFatG: Double {
        todayDietLogs.compactMap(\.totalFatG).reduce(0, +)
    }

    /// 매크로 일일 목표 (기본값; 향후 GoalMacroTargets 연동 예정)
    var dailyProteinGoal: Double { 150.0 }
    var dailyCarbsGoal: Double   { 200.0 }
    var dailyFatGoal: Double     { 60.0  }

    var proteinProgress: Double { min(todayProteinG / dailyProteinGoal, 1.0) }
    var carbsProgress: Double   { min(todayCarbsG   / dailyCarbsGoal,   1.0) }
    var fatProgress: Double     { min(todayFatG     / dailyFatGoal,     1.0) }

    // MARK: - 연속 기록일

    /// 오늘부터 거슬러 올라가며 식단 또는 운동 기록이 있는 연속 일수
    /// 주간 데이터(7일) 범위 내에서 계산하므로 최대 7일
    var streakDays: Int {
        let calendar = Calendar.current
        var streak = 0
        for offset in 0...6 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { break }
            let dateStr = dateFormatter.string(from: date)
            let hasDiet     = weekDietLogs.contains    { $0.logDate     == dateStr }
            let hasExercise = recentSessions.contains  { $0.sessionDate == dateStr }
            if hasDiet || hasExercise {
                streak += 1
            } else {
                break   // 연속이 끊기면 중지
            }
        }
        return streak
    }

    // MARK: - 7일 추세

    /// 오늘 기준 최근 7일(오래된 날부터) 일별 활동 배열
    var weeklyActivity: [DayActivity] {
        let calendar = Calendar.current
        return (0...6).reversed().compactMap { offset -> DayActivity? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let dateStr = dateFormatter.string(from: date)

            let caloriesIn = weekDietLogs
                .filter { $0.logDate == dateStr }
                .compactMap(\.totalCalories)
                .reduce(0, +)
            let caloriesBurned = recentSessions
                .filter { $0.sessionDate == dateStr }
                .compactMap(\.caloriesBurned)
                .reduce(0, +)
            let durationMinutes = recentSessions
                .filter { $0.sessionDate == dateStr }
                .compactMap(\.durationMinutes)
                .reduce(0, +)

            return DayActivity(
                date: dateStr,
                caloriesIn: caloriesIn,
                caloriesBurned: caloriesBurned,
                durationMinutes: durationMinutes
            )
        }
    }

    // MARK: - API

    func loadDashboard(apiClient: any HomeDashboardLoading) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let dietResponse     = apiClient.loadDietLogs(from: weekStart, to: today)
            async let exerciseResponse = apiClient.loadExerciseSessions()
            async let goalResponse     = apiClient.loadGoals()

            let (diet, exercise, goals) = try await (dietResponse, exerciseResponse, goalResponse)

            weekDietLogs   = diet.content
            todayDietLogs  = diet.content.filter { $0.logDate == today }
            recentSessions = exercise.content

            if let goal = goals.content.first(where: { $0.status == .ACTIVE }) {
                activeGoal = await enrichedActiveGoal(goal, apiClient: apiClient)
            } else {
                activeGoal = nil
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "데이터를 불러오지 못했습니다."
        }
    }

    private func enrichedActiveGoal(_ goal: GoalSummary, apiClient: any HomeDashboardLoading) async -> GoalSummary {
        do {
            let progress = try await apiClient.loadGoalProgress(id: goal.goalId)
            return goal.withPercentComplete(progress.percentComplete)
        } catch {
            return goal
        }
    }
}
