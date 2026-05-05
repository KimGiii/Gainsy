import XCTest

@MainActor
final class HealthCareUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("UI_TEST_RESET_STATE")
        app.launch()
    }

    func testOnboardingAppears() throws {
        XCTAssertTrue(app.staticTexts["HealthCare"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["로그인"].exists)
    }
}
