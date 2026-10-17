import XCTest

final class FirstStateLensUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testOnboardingCoursesPracticeAwardsAndPersistence() throws {
        let app = XCUIApplication()
        app.launch()

        if app.tabBars.buttons["Profile"].exists {
            app.tabBars.buttons["Profile"].tap()
            let reset = app.buttons["Reset all progress"]
            for _ in 0..<4 where !reset.isHittable { app.swipeUp() }
            reset.tap()
            app.buttons["Reset progress"].tap()
        }

        XCTAssertTrue(app.staticTexts["A study path that grows with you."].waitForExistence(timeout: 3))
        attachScreenshot(named: "Onboarding-Welcome")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Where should we begin?"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Algebra I"].exists)
        XCTAssertTrue(app.staticTexts["AP Biology"].exists)
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Make the path yours."].waitForExistence(timeout: 2))
        let nameField = app.textFields["First name or nickname"]
        nameField.tap(); nameField.typeText("Avery")
        app.buttons["Start learning"].tap()

        XCTAssertTrue(app.staticTexts["Avery"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.buttons["Learn"].exists)
        attachScreenshot(named: "Home")

        app.tabBars.buttons["Learn"].tap()
        XCTAssertTrue(app.staticTexts["Pick your next course"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["U.S. History"].exists)
        XCTAssertTrue(app.staticTexts["Algebra I"].exists)
        attachScreenshot(named: "Course-Catalog")
        app.staticTexts["U.S. History"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["COURSE PATH"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["LESSON 1 · READY"].exists)
        attachScreenshot(named: "Course-Path")
        app.navigationBars.buttons.firstMatch.tap()

        app.swipeUp()
        XCTAssertTrue(app.staticTexts["COLLEGE"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["College Algebra"].exists)
        XCTAssertTrue(app.staticTexts["General Biology I"].exists)

        app.tabBars.buttons["Home"].tap()
        app.buttons["Start first lesson"].tap()
        XCTAssertTrue(app.staticTexts["Primary-source method"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["lesson-video-player"].waitForExistence(timeout: 5))
        attachScreenshot(named: "Lesson-Notes-Video")
        let lessonTest = app.buttons["Take lesson test"]
        for _ in 0..<4 where !lessonTest.isHittable { app.swipeUp() }
        XCTAssertTrue(lessonTest.isHittable)
        lessonTest.tap()
        XCTAssertTrue(app.staticTexts["When was the petition written?"].waitForExistence(timeout: 3))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "October 24, 1787")).firstMatch.tap()
        app.buttons["Check my reasoning"].tap()
        XCTAssertTrue(app.staticTexts["Correct"].waitForExistence(timeout: 2))
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.staticTexts["Which problem do the petitioners themselves identify?"].waitForExistence(timeout: 2))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "A lack of an efficient general government")).firstMatch.tap()
        app.buttons["Check my reasoning"].tap()
        app.buttons["Finish session"].tap()
        XCTAssertTrue(app.staticTexts["Lesson complete."].waitForExistence(timeout: 2))
        app.buttons["Return home"].tap()

        app.tabBars.buttons["Awards"].tap()
        XCTAssertTrue(app.staticTexts["Awards"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["First Step"].exists)
        attachScreenshot(named: "Awards")

        app.terminate(); app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Avery"].exists)
        XCTAssertTrue(app.staticTexts["50"].exists)
        XCTAssertTrue(app.staticTexts["XP"].exists)
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Academic Emblems"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Learning Record"].exists)
        attachScreenshot(named: "Academic-Profile")
    }

    @MainActor
    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
