import XCTest
@testable import HealthCare

@MainActor
final class HomeViewModelTests: XCTestCase {

    // MARK: - calorieProgress

    func testCalorieProgress_섭취칼로리없으면0이다() {
        let vm = HomeViewModel()
        XCTAssertEqual(vm.calorieProgress, 0.0)
    }

    func testCalorieProgress_섭취칼로리가목표의절반이면0점5이다() {
        let vm = HomeViewModel()
        vm.todayDietLogs = [makeDietLog(calories: 1_000)]
        XCTAssertEqual(vm.calorieProgress, 0.5, accuracy: 0.001)
    }

    func testCalorieProgress_초과섭취해도1을넘지않는다() {
        let vm = HomeViewModel()
        vm.todayDietLogs = [makeDietLog(calories: 5_000)]
        XCTAssertEqual(vm.calorieProgress, 1.0)
    }

    func testCalorieProgress_여러로그의칼로리를합산한다() {
        let vm = HomeViewModel()
        vm.todayDietLogs = [makeDietLog(calories: 500), makeDietLog(calories: 500)]
        XCTAssertEqual(vm.calorieProgress, 0.5, accuracy: 0.001)
    }

    // MARK: - activityProgress

    func testActivityProgress_오늘운동없으면0이다() {
        let vm = HomeViewModel()
        vm.recentSessions = []
        XCTAssertEqual(vm.activityProgress, 0.0)
    }

    func testActivityProgress_오늘250kcal소모시0점5이다() {
        let vm = HomeViewModel()
        vm.recentSessions = [makeSession(date: vm.today, calories: 250)]
        XCTAssertEqual(vm.activityProgress, 0.5, accuracy: 0.001)
    }

    func testActivityProgress_과거세션은제외된다() {
        let vm = HomeViewModel()
        vm.recentSessions = [makeSession(date: "2000-01-01", calories: 999)]
        XCTAssertEqual(vm.activityProgress, 0.0)
    }

    func testActivityProgress_500kcal이상이면1로클램프된다() {
        let vm = HomeViewModel()
        vm.recentSessions = [makeSession(date: vm.today, calories: 1_000)]
        XCTAssertEqual(vm.activityProgress, 1.0)
    }

    // MARK: - loadDashboard

    func testLoadDashboard_성공시데이터가채워진다() async throws {
        let loader = MockHomeDashboardLoader(
            dietLogs: [makeDietLog(calories: 300)],
            sessions: [makeSession(date: "2026-01-01", calories: 100)],
            goals: []
        )
        let vm = HomeViewModel()

        await vm.loadDashboard(apiClient: loader)

        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(vm.todayDietLogs.count, 1)
        XCTAssertEqual(vm.recentSessions.count, 1)
        XCTAssertNil(vm.activeGoal)
    }

    func testLoadDashboard_활성목표가있으면진행률을enriched한다() async throws {
        let goal = makeGoalSummary(id: 7, status: .ACTIVE, percentComplete: nil)
        let loader = MockHomeDashboardLoader(
            dietLogs: [],
            sessions: [],
            goals: [goal],
            goalProgress: makeGoalProgress(id: 7, percent: 42.0)
        )
        let vm = HomeViewModel()

        await vm.loadDashboard(apiClient: loader)

        XCTAssertEqual(vm.activeGoal?.percentComplete, 42.0)
    }

    func testLoadDashboard_오류발생시기존데이터가유지된다() async {
        let loader = MockHomeDashboardLoader(shouldFail: true)
        let vm = HomeViewModel()
        let existingLog = makeDietLog(calories: 100)
        vm.todayDietLogs = [existingLog]

        await vm.loadDashboard(apiClient: loader)

        // silent fail — 에러 발생 시 이전 상태를 그대로 유지
        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(vm.todayDietLogs.count, 1)
    }

    func testLoadDashboard_로딩중플래그가올바르게관리된다() async {
        let loader = MockHomeDashboardLoader(dietLogs: [], sessions: [], goals: [])
        let vm = HomeViewModel()

        XCTAssertFalse(vm.isLoading)
        let task = Task { await vm.loadDashboard(apiClient: loader) }
        await task.value
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Helpers

    private func makeDietLog(calories: Double) -> DietLogSummary {
        DietLogSummary(
            dietLogId: Int.random(in: 1...10000),
            logDate: "2026-01-01",
            mealType: .BREAKFAST,
            totalCalories: calories,
            totalProteinG: 0,
            totalCarbsG: 0,
            totalFatG: 0
        )
    }

    private func makeSession(date: String, calories: Double) -> SessionSummary {
        SessionSummary(
            sessionId: Int.random(in: 1...10000),
            sessionDate: date,
            durationMinutes: 30,
            totalVolumeKg: nil,
            caloriesBurned: calories,
            calorieEstimateMethod: "MET",
            notes: nil
        )
    }

    private func makeGoalSummary(id: Int, status: GoalStatus, percentComplete: Double?) -> GoalSummary {
        GoalSummary(
            goalId: id,
            goalType: .WEIGHT_LOSS,
            targetValue: 70.0,
            targetUnit: "kg",
            targetDate: "2026-12-31",
            startDate: "2026-01-01",
            status: status,
            percentComplete: percentComplete
        )
    }

    private func makeGoalProgress(id: Int, percent: Double) -> GoalProgressResponse {
        GoalProgressResponse(
            goalId: id,
            goalType: .WEIGHT_LOSS,
            targetValue: 70.0,
            targetUnit: "kg",
            targetDate: "2026-12-31",
            startDate: "2026-01-01",
            startValue: 80.0,
            currentValue: 75.0,
            percentComplete: percent,
            daysRemaining: 200,
            projectedCompletionDate: nil,
            weeklyRateTarget: nil,
            isOnTrack: true,
            trackingStatus: "ON_TRACK",
            trackingColor: "green",
            checkpoints: nil
        )
    }
}

// MARK: - Mock

private actor MockHomeDashboardLoader: HomeDashboardLoading {
    private let dietLogs: [DietLogSummary]
    private let sessions: [SessionSummary]
    private let goals: [GoalSummary]
    private let goalProgress: GoalProgressResponse?
    private let shouldFail: Bool

    init(
        dietLogs: [DietLogSummary] = [],
        sessions: [SessionSummary] = [],
        goals: [GoalSummary] = [],
        goalProgress: GoalProgressResponse? = nil,
        shouldFail: Bool = false
    ) {
        self.dietLogs = dietLogs
        self.sessions = sessions
        self.goals = goals
        self.goalProgress = goalProgress
        self.shouldFail = shouldFail
    }

    func loadDietLogs(from: String, to: String) async throws -> DietLogListResponse {
        if shouldFail { throw APIError.unknown }
        return DietLogListResponse(content: dietLogs, page: 0, size: 10, totalElements: dietLogs.count, totalPages: 1, first: true, last: true)
    }

    func loadExerciseSessions() async throws -> SessionListResponse {
        if shouldFail { throw APIError.unknown }
        return SessionListResponse(content: sessions, pageNumber: 0, pageSize: 5, totalElements: sessions.count, totalPages: 1, first: true, last: true)
    }

    func loadGoals() async throws -> GoalListResponse {
        if shouldFail { throw APIError.unknown }
        return GoalListResponse(content: goals, pageNumber: 0, pageSize: 20, totalElements: goals.count, first: true, last: true)
    }

    func loadGoalProgress(id: Int) async throws -> GoalProgressResponse {
        if let p = goalProgress { return p }
        throw APIError.unknown
    }
}
