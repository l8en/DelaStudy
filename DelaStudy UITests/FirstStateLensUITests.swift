import XCTest
import UIKit

@MainActor
final class FirstStateLensUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func launch(reset: Bool = true, extra: [String] = [], username: String = "Avery") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"] + (reset ? ["--reset-test-data"] : []) + extra
        if app.state != .notRunning { app.terminate() }
        app.launch()
        if app.textFields["onboarding-name"].waitForExistence(timeout: 5) {
            let signingIn = app.staticTexts["Back to your studies."].exists
            let field = app.textFields["onboarding-name"]
            if (field.value as? String) != username { field.tap(); field.typeText(username) }
            let password = app.secureTextFields["profile-password"]
            password.tap()
            password.typeText("StudyTestOnly42")
            let confirmation = app.secureTextFields["confirm-profile-password"]
            if confirmation.exists { confirmation.tap(); confirmation.typeText("StudyTestOnly42\n") }
            else { password.typeText("\n") }
            capture("Identity-setup", app: app)
            if !signingIn {
                reveal(app.buttons["start-learning"], app: app)
                app.buttons["start-learning"].tap()
            }
        } else if app.buttons["start-learning"].exists { app.buttons["start-learning"].tap() }
        finishSetupIfNeeded(app)
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        return app
    }
    private func finishSetupIfNeeded(_ app: XCUIApplication) {
        guard app.buttons["setup-continue"].waitForExistence(timeout: 3) else { return }
        if app.staticTexts["Where are you starting?"].exists {
            reveal(app.buttons["11th grade"], app: app)
            app.buttons["11th grade"].tap(); app.buttons["setup-continue"].tap()
        }
        if app.staticTexts["What brings you here?"].exists {
            reveal(app.buttons["Keep up with class"], app: app)
            app.buttons["Keep up with class"].tap(); app.buttons["setup-continue"].tap()
        }
        if app.staticTexts["Make room for your subjects."].exists {
            reveal(app.buttons["History"], app: app)
            app.buttons["History"].tap(); app.buttons["setup-continue"].tap()
        }
        for _ in 0..<4 {
            if app.buttons["setup-continue"].exists { app.buttons["setup-continue"].tap() }
        }
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
    }
    private func signOut(_ app: XCUIApplication) {
        app.buttons["open-settings"].tap()
        app.buttons["sign-out"].tap()
    }
    private func revealSetupChoice(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<10 {
            let top = app.navigationBars.firstMatch.frame.maxY + 5
            let bottom = app.buttons["setup-continue"].frame.minY - 8
            if element.exists && element.isHittable && element.frame.minY >= top && element.frame.maxY <= bottom { return }
            if element.exists && element.frame.minY < top { app.swipeDown() } else { app.swipeUp() }
        }
        XCTFail("Setup choice is obscured: \(element)")
    }
    private func capture(_ name: String, app: XCUIApplication) {
        // Let the app's sub-second feedback/header transitions settle for visual QA.
        Thread.sleep(forTimeInterval: 0.65)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    private func reveal(_ element: XCUIElement, app: XCUIApplication, swipes: Int = 9) {
        for _ in 0..<swipes {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable, "Could not reach \(element)")
    }
    private func startBitePractice(_ app: XCUIApplication) {
        for _ in 0..<3 {
            let next = app.buttons["next-lesson-step"]
            if !next.exists { break }
            next.tap()
        }
        XCTAssertTrue(app.buttons["complete-study-activity"].waitForExistence(timeout: 3))
        app.buttons["complete-study-activity"].tap()
    }
    private func setSwitch(_ name: String, to enabled: Bool, app: XCUIApplication) {
        let control = app.switches[name].firstMatch
        for _ in 0..<3 {
            if control.value as? String == (enabled ? "1" : "0") { return }
            // Hit the actual switch, not the enclosing SwiftUI Form row.
            control.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
        XCTAssertEqual(control.value as? String, enabled ? "1" : "0", name)
    }

    /// Real Simulator footage, including account setup and a native local alert.
    /// Uses the test-only account store on the dedicated capture Simulator.
    func testRecordWafflesShowcase() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-test-data"]
        app.launch()
        func hold(_ seconds: Double = 1.5) { Thread.sleep(forTimeInterval: seconds) }
        func mark(_ kind: String, _ id: String) { print("SHOWCASE_\(kind)|\(id)|\(Date().timeIntervalSince1970)") }
        func scene(_ id: String, _ action: () -> Void) {
            mark("START", id); action(); hold(); mark("END", id)
        }
        func back() { app.navigationBars.buttons.element(boundBy: 0).tap() }
        func todayRoot() {
            app.tabBars.buttons["Today"].tap()
            for _ in 0..<6 {
                if app.buttons["open-profile"].exists { return }
                back()
            }
        }
        XCTAssertTrue(app.textFields["onboarding-name"].waitForExistence(timeout: 5))
        app.textFields["onboarding-name"].tap(); app.textFields["onboarding-name"].typeText("Waffles123")
        app.secureTextFields["profile-password"].tap(); app.secureTextFields["profile-password"].typeText("StudyTestOnly42\n")
        scene("account") { hold(2); app.buttons["start-learning"].tap() }
        XCTAssertTrue(app.buttons["setup-continue"].waitForExistence(timeout: 5))
        scene("setup_year") { app.buttons["11th grade"].tap(); hold(); app.buttons["setup-continue"].tap() }
        scene("setup_goal") { app.buttons["Prepare for a test"].tap(); hold(); app.buttons["setup-continue"].tap() }
        scene("setup_subjects") {
            app.buttons["Mathematics"].tap(); app.buttons["Biology"].tap(); hold(); app.buttons["setup-continue"].tap()
        }
        scene("setup_route") { hold(); app.buttons["setup-continue"].tap() }
        scene("setup_school") {
            app.buttons["setup-find-school"].tap()
            let field = app.searchFields.firstMatch; XCTAssertTrue(field.waitForExistence(timeout: 3))
            field.tap(); field.typeText("Charter School of Wilmington\n")
            let school = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Charter School of Wilmington")).firstMatch
            XCTAssertTrue(school.waitForExistence(timeout: 3)); school.tap(); hold()
            app.buttons["setup-continue"].tap()
        }
        scene("setup_rhythm") { app.buttons["20 minutes"].tap(); hold(); app.buttons["setup-continue"].tap() }
        scene("setup_ready") { hold(2); app.buttons["setup-continue"].tap() }
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        scene("today") { hold(2) }
        scene("library") {
            app.tabBars.buttons["Library"].tap(); app.buttons["All"].tap(); hold()
            app.buttons["AP preparation"].tap(); hold(); app.buttons["College"].tap(); hold()
            app.buttons["High School"].tap()
            let search = app.textFields["course-search"]; search.tap(); search.typeText("Geometry\n")
        }
        scene("outline") { app.buttons["course-geometry"].tap(); hold(); app.swipeUp(); hold(); app.swipeDown() }
        scene("lesson") {
            reveal(app.buttons["continue-unit-study"], app: app); app.buttons["continue-unit-study"].tap()
            if app.buttons["disable-lesson-focus"].waitForExistence(timeout: 2) { app.buttons["disable-lesson-focus"].tap() }
            XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 4))
            hold(2); app.buttons["next-lesson-step"].tap(); hold(2); app.buttons["next-lesson-step"].tap(); hold(2)
        }
        scene("practice") {
            app.buttons["complete-study-activity"].tap()
            app.buttons["check-choice-vertical"].tap(); app.buttons["check-answer"].tap(); hold()
            app.buttons["check-answer"].tap()
            let blank = app.textFields["blank-answer"]; blank.tap(); blank.typeText("180\n"); hold()
            app.buttons["check-answer"].tap()
            for (index, term) in ["vertical", "180", "adjacent"].enumerated() {
                let token = app.buttons["match-term-\(term)"]; let slot = app.buttons["match-slot-\(index)"]
                reveal(token, app: app)
                if index == 0 { token.press(forDuration: 0.5, thenDragTo: slot) }
                else { token.tap(); reveal(slot, app: app); slot.tap() }
                if index < 2 { app.swipeDown() }
            }
            app.buttons["check-answer"].tap(); hold(); app.buttons["check-answer"].tap(); app.buttons["check-answer"].tap()
            XCTAssertTrue(app.staticTexts["practice-saved"].waitForExistence(timeout: 3)); hold()
        }
        back(); back(); app.buttons["Clear search"].tap()
        app.textFields["course-search"].tap(); app.textFields["course-search"].typeText("Biology\n"); app.buttons["course-ap-biology"].tap()
        scene("resources") {
            app.segmentedControls.buttons["Resources"].tap(); app.buttons["resources-textbooks"].tap(); hold()
            app.buttons["resources-readings"].tap(); hold(); app.swipeDown()
            app.buttons["resources-videos"].tap(); hold()
        }
        scene("college") {
            app.tabBars.buttons["Explore"].tap()
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "College & next steps")).firstMatch.tap(); hold()
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Explore fields of study")).firstMatch.tap()
        }
        scene("plan") {
            app.tabBars.buttons["Plan"].tap(); app.buttons["new-task"].tap()
            app.textFields["task-title"].tap(); app.textFields["task-title"].typeText("Review angle relationships")
            app.navigationBars.buttons["save-task"].tap(); hold()
        }
        app.buttons["Focus on Review angle relationships"].tap()
        // Configure a real one-minute interval. The edit removes the waiting,
        // not the system notification or the user's tap on the Home Screen.
        app.buttons["Change session settings"].tap()
        for _ in 0..<24 { app.steppers.firstMatch.buttons["Decrement"].tap() }
        XCTAssertTrue(app.staticTexts["Work · 1 min"].exists)
        back(); app.swipeDown()
        let alerts = app.buttons["Notifications & Lock Screen"]; reveal(alerts, app: app); alerts.tap()
        setSwitch("Session-end alerts", to: true, app: app)
        setSwitch("Break-end alerts", to: false, app: app)
        setSwitch("Show timer on Lock Screen", to: false, app: app)
        mark("START", "permission")
        app.buttons["Set up optional alerts"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.buttons["Allow"].waitForExistence(timeout: 4) { hold(); springboard.buttons["Allow"].tap() }
        XCTAssertTrue(app.staticTexts["Session alerts enabled"].waitForExistence(timeout: 5)); hold()
        mark("END", "permission")
        back(); app.swipeDown()
        let sounds = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Study sounds")).firstMatch
        reveal(sounds, app: app); sounds.tap()
        scene("sounds") {
            let brown = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Brown noise,")).firstMatch
            brown.tap(); XCTAssertTrue(app.staticTexts["Playing · tap to pause"].waitForExistence(timeout: 8)); hold(3)
            capture("Waffles-Brown-playing-1", app: app); hold(0.3); capture("Waffles-Brown-playing-2", app: app)
            brown.tap(); XCTAssertTrue(app.staticTexts["Paused · tap to resume"].waitForExistence(timeout: 3)); hold()
            brown.tap(); XCTAssertTrue(app.staticTexts["Playing · tap to pause"].waitForExistence(timeout: 3)); hold(2)
        }
        back(); app.swipeDown(); app.buttons["Start Focus"].tap()
        let began = Date()
        scene("zen") {
            app.buttons["Enter Zen"].tap(); XCTAssertTrue(app.buttons["Exit Zen"].waitForExistence(timeout: 4)); hold(3)
            app.buttons["Hide tasks"].tap(); hold(2); app.tap(); app.buttons["Exit Zen"].tap()
        }
        // Leave a different tab active: tapping the alert must route to Focus.
        app.tabBars.buttons["Library"].tap(); XCUIDevice.shared.press(.home); springboard.swipeRight()
        let remainingWait = max(0, 55 - Date().timeIntervalSince(began))
        hold(remainingWait)
        mark("START", "notification")
        let notification = springboard.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Study interval complete")).firstMatch
        XCTAssertTrue(notification.waitForExistence(timeout: 15), springboard.debugDescription)
        capture("Waffles-Home-Screen-notification", app: springboard); hold(1)
        notification.tap()
        XCTAssertTrue(app.buttons["Start break"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Review angle relationships"].exists)
        capture("Waffles-Notification-opened-Focus", app: app); hold(2)
        mark("END", "notification")
        app.buttons["End session"].tap(); app.buttons["End and save time"].tap()
        if app.navigationBars.buttons["Done"].exists { app.navigationBars.buttons["Done"].tap() }
        scene("profile") {
            todayRoot(); app.buttons["open-profile"].tap()
            XCTAssertTrue(app.staticTexts["Waffles123"].waitForExistence(timeout: 4)); hold(3)
            app.buttons["profile-tab-Stats"].tap(); hold(2)
        }
    }

    func testRecordWafflesNotificationAndProfile() throws {
        let app = launch(reset: false, username: "Waffles123")
        func hold(_ seconds: Double = 1.5) { Thread.sleep(forTimeInterval: seconds) }
        func mark(_ kind: String, _ id: String) { print("SHOWCASE_\(kind)|\(id)|\(Date().timeIntervalSince1970)") }
        func back() { app.navigationBars.buttons.element(boundBy: 0).tap() }
        func toggle(_ name: String, to enabled: Bool) {
            setSwitch(name, to: enabled, app: app)
        }
        app.tabBars.buttons["Explore"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Focus & Zen")).firstMatch.tap()
        if app.buttons["End session"].exists { app.buttons["End session"].tap(); app.buttons["End and save time"].tap() }
        let task = app.textFields["Session task"]; task.tap()
        let existing = task.value as? String ?? ""
        task.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + "Review angle relationships\n")
        let settings = app.buttons["Notifications & Lock Screen"]; reveal(settings, app: app); settings.tap()
        toggle("Session-end alerts", to: true)
        toggle("Break-end alerts", to: false)
        toggle("Show timer on Lock Screen", to: false)
        capture("Waffles-Alerts-enabled", app: app)
        back(); reveal(settings, app: app); settings.tap()
        XCTAssertEqual(app.switches["Session-end alerts"].firstMatch.value as? String, "1")
        XCTAssertEqual(app.switches["Break-end alerts"].firstMatch.value as? String, "0")
        XCTAssertEqual(app.switches["Show timer on Lock Screen"].firstMatch.value as? String, "0")
        mark("START", "permission_verified"); hold(3); mark("END", "permission_verified")
        back(); app.swipeDown(); app.swipeDown()
        app.buttons["Start Focus"].tap()
        let began = Date()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 4))
        app.tabBars.buttons["Library"].tap(); XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // The first Home Screen has ordinary apps, without the test runner icon.
        springboard.swipeRight(); hold()
        hold(max(0, 54 - Date().timeIntervalSince(began)))
        mark("START", "notification")
        let notification = springboard.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Study interval complete")).firstMatch
        XCTAssertTrue(notification.waitForExistence(timeout: 15), springboard.debugDescription)
        capture("Waffles-Home-Screen-notification", app: springboard); hold(1)
        notification.tap()
        XCTAssertTrue(app.buttons["Start break"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Review angle relationships"].exists)
        capture("Waffles-Notification-opened-Focus", app: app); hold(2)
        mark("END", "notification")
        app.buttons["End session"].tap(); app.buttons["End and save time"].tap()
        app.navigationBars.buttons["Done"].tap()
        app.tabBars.buttons["Today"].tap()
        mark("START", "profile")
        app.buttons["open-profile"].tap()
        XCTAssertTrue(app.staticTexts["Waffles123"].waitForExistence(timeout: 4)); hold(3)
        app.buttons["profile-tab-Stats"].tap(); hold(2)
        mark("END", "profile")
    }

    func testWafflesSoundPlaybackStates() throws {
        let app = launch(reset: false, username: "Waffles123")
        app.buttons["open-profile"].tap()
        XCTAssertTrue(app.staticTexts["Waffles123"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "20 XP")).firstMatch.exists)
        app.tabBars.buttons["Explore"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Focus & Zen")).firstMatch.tap()
        let sounds = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Study sounds")).firstMatch
        reveal(sounds, app: app); sounds.tap()
        let brown = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Brown noise,")).firstMatch
        brown.tap()
        XCTAssertTrue(app.staticTexts["Playing · tap to pause"].waitForExistence(timeout: 8))
        print("SOUND_GLYPH_RECT|22|\(brown.frame.midY - 23)|46|46")
        capture("Sound-playing-A", app: app)
        Thread.sleep(forTimeInterval: 0.31)
        capture("Sound-playing-B", app: app)
        brown.tap()
        XCTAssertTrue(app.staticTexts["Paused · tap to resume"].waitForExistence(timeout: 3))
        capture("Sound-paused-A", app: app)
        Thread.sleep(forTimeInterval: 0.31)
        capture("Sound-paused-B", app: app)
        let stop = app.buttons["Stop sound"]; reveal(stop, app: app); stop.tap()
    }

    /// Opt-in capture journey. Ordinary accounts and app behavior are unchanged.
    /// Epoch markers let the local editor remove setup/credentials and preserve
    /// real interactions instead of assembling a slideshow of screenshots.
    func testRecordStudentShowcase() throws {
        let app = launch(username: "MhamedDemo")
        func hold(_ seconds: TimeInterval = 2) { Thread.sleep(forTimeInterval: seconds) }
        func scene(_ id: String, _ action: () -> Void) {
            print("SHOWCASE_START|\(id)|\(Date().timeIntervalSince1970)")
            action(); hold()
            print("SHOWCASE_END|\(id)|\(Date().timeIntervalSince1970)")
        }
        func back() { app.navigationBars.buttons.element(boundBy: 0).tap() }
        func todayRoot() {
            app.tabBars.buttons["Today"].tap()
            for _ in 0..<5 {
                if app.buttons["open-profile"].exists { return }
                let previous = app.navigationBars.buttons.element(boundBy: 0)
                guard previous.exists else { break }
                previous.tap()
            }
            XCTAssertTrue(app.buttons["open-profile"].waitForExistence(timeout: 3))
        }
        func search(_ term: String) {
            if app.buttons["Clear search"].exists { app.buttons["Clear search"].tap() }
            let field = app.textFields["course-search"]; field.tap(); field.typeText(term + "\n")
        }
        // Earn the starter achievement through real practice before filming.
        app.buttons["lesson-course-outline"].tap()
        reveal(app.buttons["course-study-next"], app: app); app.buttons["course-study-next"].tap()
        if app.buttons["disable-lesson-focus"].exists { app.buttons["disable-lesson-focus"].tap() }
        reveal(app.buttons["Practice this lesson"], app: app); app.buttons["Practice this lesson"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "October 24, 1787")).firstMatch.tap()
        app.buttons["Check my reasoning"].tap()
        reveal(app.buttons["Continue"], app: app); app.buttons["Continue"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "A lack of an efficient general government")).firstMatch.tap()
        app.buttons["Check my reasoning"].tap()
        reveal(app.buttons["Finish session"], app: app); app.buttons["Finish session"].tap()
        app.buttons["Return home"].tap(); todayRoot()
        app.swipeDown(); hold()

        scene("today") { hold(7) }
        scene("library") {
            app.tabBars.buttons["Library"].tap(); app.buttons["All"].tap(); hold()
            app.buttons["AP preparation"].tap(); hold()
            app.buttons["College"].tap(); hold()
            app.buttons["High School"].tap(); search("Geometry")
        }
        scene("outline") {
            app.buttons["course-geometry"].tap(); hold()
            let unit = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Reasoning with angles")).firstMatch
            reveal(unit, app: app); unit.tap(); hold()
            app.swipeDown(); app.swipeDown()
        }
        scene("lesson") {
            reveal(app.buttons["continue-unit-study"], app: app); app.buttons["continue-unit-study"].tap()
            XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 5)); hold()
            if app.buttons["disable-lesson-focus"].exists { app.buttons["disable-lesson-focus"].tap() }
            hold(); app.buttons["next-lesson-step"].tap(); hold(); app.buttons["next-lesson-step"].tap(); hold()
        }
        scene("practice") {
            app.buttons["complete-study-activity"].tap()
            app.buttons["check-choice-180"].tap(); app.buttons["check-answer"].tap(); hold()
            app.buttons["check-answer"].tap(); app.buttons["check-choice-vertical"].tap()
            app.buttons["check-answer"].tap(); hold(); app.buttons["check-answer"].tap()
            let blank = app.textFields["blank-answer"]; blank.tap(); blank.typeText("180\n")
            hold(); app.buttons["check-answer"].tap()
            for (index, term) in ["vertical", "180", "adjacent"].enumerated() {
                let token = app.buttons["match-term-\(term)"]; let slot = app.buttons["match-slot-\(index)"]
                reveal(token, app: app)
                if index == 0 { token.press(forDuration: 0.6, thenDragTo: slot) }
                else { token.tap(); reveal(slot, app: app); slot.tap() }
                if index < 2 { app.swipeDown() }
            }
            app.buttons["check-answer"].tap(); hold()
            app.buttons["check-answer"].tap(); app.buttons["check-answer"].tap()
            XCTAssertTrue(app.staticTexts["practice-saved"].waitForExistence(timeout: 3)); hold()
        }
        back(); back(); search("Biology")
        app.buttons["course-ap-biology"].tap()
        scene("resources") {
            app.segmentedControls.buttons["Resources"].tap(); hold()
            app.buttons["resources-textbooks"].tap(); hold()
            app.buttons["resources-readings"].tap(); hold()
            let chapter = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "resource-reading-")).firstMatch
            chapter.tap(); XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 5)); hold(); back()
            app.swipeDown(); app.swipeDown(); app.buttons["resources-videos"].tap()
            app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "resource-video-")).firstMatch.tap()
            XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 8)); hold(4)
        }
        back(); back(); search("U.S. History"); app.buttons["course-first-state-civics"].tap()
        scene("delaware") {
            app.segmentedControls.buttons["Resources"].tap()
            reveal(app.buttons["Standards & skills"], app: app); app.buttons["Standards & skills"].tap(); hold(4)
            app.swipeUp()
        }
        scene("plan") {
            app.tabBars.buttons["Plan"].tap(); app.buttons["new-task"].tap()
            let field = app.textFields["task-title"]; field.tap(); field.typeText("Review angle relationships")
            app.navigationBars.buttons["save-task"].tap(); hold()
        }
        scene("focus") {
            app.buttons["Focus on Review angle relationships"].tap()
            let sounds = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Study sounds")).firstMatch
            reveal(sounds, app: app); sounds.tap()
            let brown = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Brown noise,")).firstMatch
            reveal(brown, app: app); brown.tap(); hold(); back()
            app.swipeDown(); app.buttons["Start Focus"].tap(); hold(3)
            app.buttons["Enter Zen"].tap(); XCTAssertTrue(app.buttons["Exit Zen"].waitForExistence(timeout: 4)); hold()
            app.buttons["Hide tasks"].tap(); hold(); app.tap(); app.buttons["Exit Zen"].tap()
            app.buttons["Pause"].tap()
        }
        app.buttons["End session"].tap(); app.buttons["End and save time"].tap()
        scene("profile") {
            todayRoot(); app.buttons["open-profile"].tap(); hold(3)
            app.buttons["profile-tab-Stats"].tap(); hold()
            app.buttons["profile-tab-Record"].tap()
        }
        back()
        scene("college") {
            app.tabBars.buttons["Explore"].tap()
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "College & next steps")).firstMatch.tap(); hold(3)
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Explore fields of study")).firstMatch.tap()
        }
        todayRoot(); app.swipeDown()
        scene("closing") { hold(6) }
    }

    func testRecordShowcaseSourceEvidence() throws {
        let app = launch(reset: false, username: "MhamedDemo")
        func hold(_ seconds: TimeInterval = 2) { Thread.sleep(forTimeInterval: seconds) }
        func mark(_ kind: String, _ id: String) { print("SHOWCASE_\(kind)|\(id)|\(Date().timeIntervalSince1970)") }
        app.tabBars.buttons["Library"].tap(); app.buttons["All"].tap()
        let search = app.textFields["course-search"]; search.tap(); search.typeText("U.S. History\n")
        app.buttons["course-first-state-civics"].tap()
        reveal(app.buttons["course-study-next"], app: app); app.buttons["course-study-next"].tap()
        if app.buttons["disable-lesson-focus"].exists { app.buttons["disable-lesson-focus"].tap() }
        mark("START", "delaware_sources"); hold()
        let credits = app.buttons["Lesson credits"]
        reveal(credits, app: app); credits.tap(); app.swipeUp(); hold(4)
        mark("END", "delaware_sources")
        app.navigationBars.buttons.element(boundBy: 0).tap(); app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Clear search"].tap(); search.tap(); search.typeText("Algebra I\n")
        app.buttons["course-algebra-i"].tap()
        mark("START", "delaware_standards")
        app.segmentedControls.buttons["Resources"].tap()
        reveal(app.buttons["Standards & skills"], app: app); app.buttons["Standards & skills"].tap()
        XCTAssertTrue(app.staticTexts["HSA-REI.B.3"].waitForExistence(timeout: 4)); hold(4)
        mark("END", "delaware_standards")
    }

    func testBiteLessonResumesAndLeadsIntoTaughtPractice() throws {
        var app = launch()
        app.tabBars.buttons["Library"].tap()
        app.textFields["course-search"].tap(); app.textFields["course-search"].typeText("Geometry\n")
        app.buttons["course-geometry"].tap(); app.buttons["continue-unit-study"].tap()
        XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 4))
        XCTAssertEqual(app.staticTexts["lesson-step-position"].label, "1 of 3")
        XCTAssertFalse(app.webViews.firstMatch.exists)
        XCTAssertFalse(app.buttons["complete-study-activity"].exists)
        if app.buttons["disable-lesson-focus"].exists { app.buttons["disable-lesson-focus"].tap() }
        capture("Bites-Angles-first-step", app: app)
        app.buttons["next-lesson-step"].tap()
        XCTAssertEqual(app.staticTexts["lesson-step-position"].label, "2 of 3")
        capture("Bites-Angles-example", app: app)
        app.terminate(); app = launch(reset: false)
        app.buttons["continue-unit-study-home"].tap()
        XCTAssertEqual(app.staticTexts["lesson-step-position"].label, "2 of 3")
        app.buttons["previous-lesson-step"].tap()
        XCTAssertEqual(app.staticTexts["lesson-step-position"].label, "1 of 3")
        app.buttons["next-lesson-step"].tap(); app.buttons["next-lesson-step"].tap()
        XCTAssertEqual(app.staticTexts["lesson-step-position"].label, "3 of 3")
        capture("Bites-Angles-third-step", app: app)
        app.buttons["complete-study-activity"].tap()
        XCTAssertTrue(app.buttons["check-choice-vertical"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["enable-lesson-focus"].exists)
        capture("Bites-Taught-idea-in-practice", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["lesson-course-outline"].tap()
        app.segmentedControls.buttons["Resources"].tap()
        XCTAssertFalse(app.buttons["continue-unit-study"].exists)
        XCTAssertTrue(app.buttons["resources-videos"].waitForExistence(timeout: 3))
        app.buttons["resources-videos"].tap()
        XCTAssertTrue(app.staticTexts["No videos linked to this course yet."].exists)
        capture("Bites-Resources-empty-category", app: app)
        app.segmentedControls.buttons["Lessons"].tap()
        XCTAssertTrue(app.buttons["continue-unit-study"].exists)
    }

    func testCourseResourcesAreSeparateAndOpenVideoBookAndOfflineChapter() throws {
        let app = launch()
        app.tabBars.buttons["Library"].tap()
        app.textFields["course-search"].tap(); app.textFields["course-search"].typeText("Biology\n")
        app.buttons["course-ap-biology"].tap()
        app.segmentedControls.buttons["Resources"].tap()
        XCTAssertTrue(app.buttons["resources-videos"].waitForExistence(timeout: 3))
        capture("Resources-Categories", app: app)
        app.buttons["resources-textbooks"].tap()
        XCTAssertEqual(app.buttons["resources-textbooks"].value as? String, "Expanded")
        let book = app.buttons["resource-link-https://openstax.org/details/books/biology-2e"]
        XCTAssertTrue(book.waitForExistence(timeout: 3))
        capture("Resources-Textbook-dropdown", app: app)
        book.tap()
        let browserBar = app.otherElements["TopBrowserBar"]
        XCTAssertTrue(browserBar.buttons["Close"].waitForExistence(timeout: 8))
        XCTAssertTrue((browserBar.buttons["URL"].value as? String ?? "").contains("openstax.org"))
        capture("Resources-External-textbook", app: app)
        browserBar.buttons["Close"].tap()
        app.buttons["resources-readings"].tap()
        let chapter = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "resource-reading-")).firstMatch
        XCTAssertTrue(chapter.waitForExistence(timeout: 3))
        chapter.tap()
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["open-original-resource"].exists)
        capture("Resources-Full-offline-chapter", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.swipeDown(); app.swipeDown()
        app.buttons["resources-videos"].tap()
        let video = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "resource-video-")).firstMatch
        XCTAssertTrue(video.waitForExistence(timeout: 3))
        capture("Resources-Video-dropdown", app: app)
        video.tap()
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Open YouTube"].exists)
        capture("Resources-In-app-video", app: app)
    }

    func testBitesAndResourceDropdownsInNativeAccessibleAppearance() throws {
        try XCTSkipUnless(UIAccessibility.isReduceMotionEnabled, "Run with native iOS Reduce Motion enabled.")
        let app = launch()
        reveal(app.buttons["continue-unit-study-home"], app: app); app.buttons["continue-unit-study-home"].tap()
        app.buttons["disable-lesson-focus"].tap()
        XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["next-lesson-step"].isHittable)
        XCTAssertGreaterThanOrEqual(app.buttons["next-lesson-step"].frame.height, 44)
        capture("Bites-Native-dark-large-reduced-motion", app: app)
        app.buttons["next-lesson-step"].tap()
        XCTAssertTrue(app.buttons["previous-lesson-step"].isHittable)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        reveal(app.buttons["lesson-course-outline"], app: app); app.buttons["lesson-course-outline"].tap()
        app.segmentedControls.buttons["Resources"].tap()
        reveal(app.buttons["resources-textbooks"], app: app); app.buttons["resources-textbooks"].tap()
        XCTAssertEqual(app.buttons["resources-textbooks"].value as? String, "Expanded")
        capture("Resources-Native-dark-large-dropdown", app: app)
    }

    func testOneTapLessonAndFocusChoicePersistence() throws {
        var app = launch()
        let start = app.buttons["continue-unit-study-home"]
        XCTAssertTrue(start.isHittable)
        XCTAssertEqual(start.label, "Start lesson")
        capture("LessonEntry-Today", app: app)
        start.tap()
        XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["enable-lesson-focus"].waitForExistence(timeout: 3))
        capture("LessonEntry-Focus-offer", app: app)
        app.buttons["disable-lesson-focus"].tap()
        XCTAssertFalse(app.buttons["enable-lesson-focus"].exists)
        XCTAssertEqual(app.buttons["Focus on this reading"].value as? String, "Off")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertEqual(app.buttons["continue-unit-study-home"].label, "Continue lesson")
        app.buttons["continue-unit-study-home"].tap()
        XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["enable-lesson-focus"].exists)
        app.terminate(); app = launch(reset: false)
        XCTAssertEqual(app.buttons["continue-unit-study-home"].label, "Continue lesson")
        app.buttons["continue-unit-study-home"].tap()
        XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["enable-lesson-focus"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Library"].tap()
        let search = app.textFields["course-search"]; search.tap(); search.typeText("Geometry\n")
        app.buttons["course-geometry"].tap()
        XCTAssertTrue(app.buttons["continue-unit-study"].isHittable)
        capture("LessonEntry-Course-start", app: app)
        app.buttons["continue-unit-study"].tap()
        XCTAssertTrue(app.buttons["enable-lesson-focus"].waitForExistence(timeout: 4))
        app.buttons["enable-lesson-focus"].tap()
        XCTAssertFalse(app.buttons["enable-lesson-focus"].exists)
        XCTAssertEqual(app.buttons["Focus on this reading"].value as? String, "Running")
        XCTAssertTrue(app.staticTexts["lesson-step-body"].exists)
        capture("LessonEntry-Focus-enabled-in-place", app: app)
        app.buttons["Focus on this reading"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        capture("LessonEntry-Linked-timer", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        reveal(app.buttons["course-study-next"], app: app); app.buttons["course-study-next"].tap()
        XCTAssertTrue(app.buttons["Your note"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["enable-lesson-focus"].exists)
        app.buttons["Focus"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        // Entering a different lesson must keep the original running task.
        XCTAssertTrue(app.staticTexts["Angle relationships"].exists)
    }

    func testLessonFocusSettingPersistsAndFoundationPromptDoesNotRepeat() throws {
        var app = launch()
        app.buttons["open-profile"].tap(); app.buttons["open-settings"].tap(); app.buttons["focus-settings"].tap()
        let setting = app.switches["lesson-focus-prompts"]
        XCTAssertEqual(setting.value as? String, "1")
        setting.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap(); XCTAssertEqual(setting.value as? String, "0")
        capture("LessonEntry-Focus-preference", app: app)
        app.terminate(); app = launch(reset: false)
        app.buttons["open-profile"].tap(); app.buttons["open-settings"].tap(); app.buttons["focus-settings"].tap()
        XCTAssertEqual(app.switches["lesson-focus-prompts"].value as? String, "0")
        app.navigationBars.buttons.element(boundBy: 0).tap(); app.navigationBars.buttons["Done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["continue-unit-study-home"].tap()
        XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["enable-lesson-focus"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["open-profile"].tap(); app.buttons["open-settings"].tap(); app.buttons["focus-settings"].tap()
        app.switches["lesson-focus-prompts"].coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap(); app.navigationBars.buttons["Done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["lesson-course-outline"].tap()
        reveal(app.buttons["course-study-next"], app: app); app.buttons["course-study-next"].tap()
        XCTAssertTrue(app.buttons["enable-lesson-focus"].waitForExistence(timeout: 3))
        capture("LessonEntry-Foundation-offer", app: app)
        app.buttons["disable-lesson-focus"].tap()
        app.buttons["Your note"].tap(); app.navigationBars.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Your note"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["enable-lesson-focus"].exists)
    }

    func testLessonEntryDarkLargeAndReducedMotionLayout() throws {
        try XCTSkipUnless(UIAccessibility.isReduceMotionEnabled, "Run with native iOS Reduce Motion enabled.")
        let app = launch()
        capture("LessonEntry-Today-accessibility", app: app)
        reveal(app.buttons["continue-unit-study-home"], app: app); app.buttons["continue-unit-study-home"].tap()
        XCTAssertTrue(app.buttons["enable-lesson-focus"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["enable-lesson-focus"].isHittable && app.buttons["disable-lesson-focus"].isHittable)
        XCTAssertGreaterThanOrEqual(app.buttons["disable-lesson-focus"].frame.height, 44)
        capture("LessonEntry-Focus-offer-accessibility", app: app)
        app.buttons["disable-lesson-focus"].tap()
        XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["enable-lesson-focus"].exists)
        capture("LessonEntry-Reading-accessibility", app: app)
    }

    func testStudentOnboardingResumesAndConfiguresDesk() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-test-data"]
        app.launch()
        app.textFields["onboarding-name"].tap(); app.textFields["onboarding-name"].typeText("OrbitStudent")
        app.secureTextFields["profile-password"].tap(); app.secureTextFields["profile-password"].typeText("OrbitTestOnly42\n")
        app.buttons["start-learning"].tap()
        XCTAssertTrue(app.staticTexts["Where are you starting?"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["setup-continue"].isEnabled)
        XCTAssertFalse(app.tabBars.buttons["Today"].exists)
        capture("Student-Year", app: app)
        app.buttons["12th grade"].tap(); app.buttons["setup-continue"].tap()
        app.buttons["Prepare for a test"].tap(); capture("Student-Goal", app: app)
        app.buttons["setup-continue"].tap()
        XCTAssertFalse(app.buttons["setup-continue"].isEnabled)
        app.buttons["Mathematics"].tap(); app.buttons["Biology"].tap()
        capture("Student-Subjects", app: app)
        app.terminate()
        app.launchArguments = ["--ui-testing"]; app.launch()
        XCTAssertTrue(app.secureTextFields["profile-password"].waitForExistence(timeout: 4))
        app.secureTextFields["profile-password"].tap(); app.secureTextFields["profile-password"].typeText("OrbitTestOnly42\n")
        XCTAssertTrue(app.staticTexts["Make room for your subjects."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Mathematics"].isSelected && app.buttons["Biology"].isSelected)
        capture("Student-Subjects-restored", app: app)
        app.buttons["setup-continue"].tap(); app.buttons["AP preparation"].tap()
        capture("Student-Route", app: app); app.buttons["setup-continue"].tap()
        app.buttons["setup-find-school"].tap()
        let search = app.searchFields.firstMatch; XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.tap(); search.typeText("MOT")
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "MOT Charter")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["setup-school-name"].waitForExistence(timeout: 3))
        capture("Student-School", app: app); app.buttons["setup-continue"].tap()
        capture("Student-Rhythm-choices", app: app)
        revealSetupChoice(app.buttons["20 minutes"], app: app)
        app.buttons["20 minutes"].tap()
        XCTAssertTrue(app.buttons["20 minutes"].isSelected)
        revealSetupChoice(app.buttons["50 / 10"], app: app); app.buttons["50 / 10"].tap()
        revealSetupChoice(app.buttons["Brown noise"], app: app); app.buttons["Brown noise"].tap()
        XCTAssertTrue(app.buttons["Brown noise"].isSelected)
        capture("Student-Rhythm", app: app); app.buttons["setup-continue"].tap()
        XCTAssertTrue(app.staticTexts["Your lens is ready."].waitForExistence(timeout: 3))
        reveal(app.switches["Add my first study task"], app: app); app.switches["Add my first study task"].tap()
        capture("Student-Ready-plan", app: app)
        app.buttons["setup-continue"].tap()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["daily-focus-lens"].label.contains("0 of 20"))
        capture("Student-Personalized-desk", app: app)
        app.buttons["daily-focus-lens"].tap()
        XCTAssertTrue(app.staticTexts["Brown noise · 50 minutes of work"].waitForExistence(timeout: 3))
        app.buttons["Change session settings"].tap()
        XCTAssertTrue(app.steppers["Work · 50 min"].exists)
        capture("Student-Focus-settings", app: app)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.secureTextFields["profile-password"].waitForExistence(timeout: 4))
        app.secureTextFields["profile-password"].tap(); app.secureTextFields["profile-password"].typeText("OrbitTestOnly42\n")
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["setup-continue"].exists)
        app.buttons["open-profile"].tap()
        XCTAssertTrue(app.staticTexts["12th grade · AP preparation"].waitForExistence(timeout: 3))
        app.buttons["open-settings"].tap()
        capture("Student-Simple-settings", app: app)
        XCTAssertTrue(app.buttons["edit-study-preferences"].exists)
        XCTAssertFalse(app.switches["Session-end alerts"].exists)
        app.buttons["edit-study-preferences"].tap(); app.buttons["9th grade"].tap()
        app.navigationBars.buttons["Cancel"].tap()
        app.navigationBars.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["12th grade · AP preparation"].exists)
    }

    func testStudentSetupLargeDarkAndSettingsNavigation() throws {
        let app = launch(extra: ["--review-large", "--review-dark"])
        app.buttons["open-profile"].tap(); app.buttons["open-settings"].tap()
        capture("Student-Settings-large-dark", app: app)
        app.buttons["edit-study-preferences"].tap()
        capture("Student-Year-large-dark", app: app)
        for index in 0..<6 {
            app.buttons["setup-continue"].tap()
            if index == 1 { capture("Student-Subjects-large-dark", app: app) }
            if index == 3 { capture("Student-School-large-dark", app: app) }
            if index == 4 { capture("Student-Rhythm-large-dark", app: app) }
        }
        capture("Student-Ready-large-dark", app: app)
        reveal(app.switches["Add my first study task"], app: app)
        app.buttons["setup-continue"].tap()
        XCTAssertTrue(app.buttons["edit-study-preferences"].waitForExistence(timeout: 4))
        app.buttons["focus-settings"].tap()
        capture("Student-Focus-large-dark", app: app)
        app.buttons["Advanced session options"].tap()
        XCTAssertTrue(app.switches["Quiet in-app prompts"].exists)
        capture("Student-Advanced-large-dark", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        reveal(app.buttons["notification-settings"], app: app); app.buttons["notification-settings"].tap()
        XCTAssertTrue(app.switches["Session-end alerts"].exists)
        capture("Student-Alerts-large-dark", app: app)
    }

    func testLensDeskMaterialsAndRecallPersistence() throws {
        var app = launch()
        capture("LensDesk-Today", app: app)
        app.buttons["intake-paste"].tap()
        app.textFields["material-title"].tap(); app.textFields["material-title"].typeText("Cell membrane class notes")
        let source = app.textViews["material-source-text"]
        source.tap(); source.typeText("The cell membrane regulates transport into and out of the cell.")
        app.buttons["save-material"].tap()
        XCTAssertTrue(app.buttons["open-materials"].waitForExistence(timeout: 3))
        app.buttons["open-materials"].tap()
        app.buttons["material-Cell membrane class notes"].tap()
        capture("LensDesk-Material-source", app: app)
        app.segmentedControls["material-tabs"].buttons["Notes"].tap()
        let notes = app.textViews["Material notes"]; notes.tap(); notes.typeText("Check diffusion before the quiz.")
        reveal(app.buttons["save-material-notes"], app: app); app.buttons["save-material-notes"].tap()
        app.swipeDown()
        app.segmentedControls["material-tabs"].buttons["Cards"].tap()
        app.buttons["Add recall card"].tap()
        app.textFields["card-question"].tap(); app.textFields["card-question"].typeText("What regulates transport?")
        app.textFields["card-answer"].tap(); app.textFields["card-answer"].typeText("The cell membrane.")
        app.buttons["save-card"].tap()
        capture("LensDesk-Cards", app: app)
        app.buttons["Review cards"].tap()
        XCTAssertTrue(app.staticTexts["What regulates transport?"].waitForExistence(timeout: 3))
        app.buttons["Reveal answer"].tap()
        XCTAssertTrue(app.staticTexts["The cell membrane."].waitForExistence(timeout: 3))
        capture("LensDesk-Recall-revealed", app: app)
        app.buttons["Recalled it"].tap()
        XCTAssertTrue(app.staticTexts["Round complete"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()
        app.terminate(); app = launch(reset: false)
        app.buttons["open-materials"].tap(); app.buttons["material-Cell membrane class notes"].tap()
        app.segmentedControls["material-tabs"].buttons["Notes"].tap()
        XCTAssertTrue((app.textViews["Material notes"].value as? String)?.contains("Check diffusion") == true)
        app.segmentedControls["material-tabs"].buttons["Cards"].tap()
        XCTAssertTrue(app.staticTexts["1 self-reviews"].exists)
        capture("LensDesk-Material-restored", app: app)
    }

    func testLensDeskAcademicSetupAndProfileTabs() throws {
        let app = launch()
        app.buttons["open-profile"].tap(); app.buttons["open-settings"].tap()
        capture("Student-Settings", app: app)
        app.buttons["edit-study-preferences"].tap()
        app.buttons["12th grade"].tap(); capture("LensDesk-Year", app: app)
        app.buttons["setup-continue"].tap()
        app.buttons["Prepare for a test"].tap(); app.buttons["setup-continue"].tap()
        app.buttons["setup-continue"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "AP preparation")).firstMatch.tap()
        capture("LensDesk-Route", app: app); app.buttons["setup-continue"].tap()
        app.buttons["setup-find-school"].tap()
        let search = app.searchFields.firstMatch; XCTAssertTrue(search.waitForExistence(timeout: 4))
        search.tap(); search.typeText("MOT")
        capture("LensDesk-School-search", app: app)
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "MOT Charter")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["setup-school-name"].waitForExistence(timeout: 3))
        app.buttons["setup-continue"].tap()
        app.buttons["setup-continue"].tap()
        capture("Student-Ready", app: app)
        app.buttons["setup-continue"].tap()
        app.navigationBars.buttons["Done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Library"].tap()
        capture("LensDesk-AP-library", app: app)
        XCTAssertTrue(app.staticTexts["10 paths"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Today"].tap(); app.buttons["open-profile"].tap()
        XCTAssertTrue(app.staticTexts["12th grade · AP preparation"].waitForExistence(timeout: 3))
        capture("LensDesk-Profile-record", app: app)
        reveal(app.buttons["profile-tab-Stats"], app: app); app.buttons["profile-tab-Stats"].tap()
        capture("LensDesk-Profile-stats", app: app)
        app.buttons["profile-tab-School"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "School & academic goals")).firstMatch.exists)
        capture("LensDesk-Profile-school", app: app)
    }

    func testLensDeskPDFPhotoAndVideoIntake() throws {
        let app = launch(extra: ["--import-fixtures"])
        app.buttons["intake-file"].tap()
        app.buttons["Load test PDF"].tap()
        let source = app.textViews["material-source-text"]
        let containsPDFText = NSPredicate(format: "value CONTAINS %@", "regulates transport")
        expectation(for: containsPDFText, evaluatedWith: source)
        waitForExpectations(timeout: 8)
        capture("LensDesk-PDF-extraction", app: app)
        app.buttons["save-material"].tap()
        app.buttons["intake-photo"].tap()
        app.buttons["Recognize test photo"].tap()
        expectation(for: containsPDFText, evaluatedWith: app.textViews["material-source-text"])
        waitForExpectations(timeout: 12)
        capture("LensDesk-Photo-OCR", app: app)
        app.buttons["save-material"].tap()
        app.buttons["intake-youtube"].tap()
        app.textFields["material-title"].tap(); app.textFields["material-title"].typeText("A class video")
        let link = app.textFields["material-video-url"]
        link.tap(); link.typeText("https://example.org/not-youtube")
        app.buttons["save-material"].tap()
        XCTAssertTrue(app.staticTexts["import-error"].waitForExistence(timeout: 3))
        app.buttons["Clear video link"].tap(); link.tap()
        link.typeText("https://www.youtube.com/watch?v=aircAruvnKk")
        app.buttons["save-material"].tap()
        app.buttons["open-materials"].tap()
        XCTAssertTrue(app.buttons["material-Photo OCR test"].waitForExistence(timeout: 3))
        app.buttons["material-A class video"].tap()
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 8))
        capture("LensDesk-Video-player", app: app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "open-material-youtube").firstMatch.exists)
        let play = app.webViews.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Play")).firstMatch
        if play.waitForExistence(timeout: 8), play.isHittable { play.tap(); capture("LensDesk-Video-play-request", app: app) }
        app.buttons["edit-material"].tap()
        app.buttons["Clear video link"].tap()
        app.textFields["material-video-url"].tap(); app.textFields["material-video-url"].typeText("https://youtu.be/00000000000")
        app.buttons["save-material"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Player unavailable")).firstMatch.waitForExistence(timeout: 16)
            || app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Player unavailable")).firstMatch.exists)
        capture("LensDesk-Video-unavailable", app: app)
    }

    func testLensDeskDarkAndLargeLayouts() throws {
        var app = launch(extra: ["--review-dark"])
        capture("LensDesk-Today-dark", app: app)
        app.buttons["intake-paste"].tap()
        app.textFields["material-title"].tap(); app.textFields["material-title"].typeText("A dark-mode note")
        capture("LensDesk-Import-dark-keyboard", app: app)
        app.navigationBars.buttons["Cancel"].tap()
        app.buttons["open-profile"].tap()
        capture("LensDesk-Profile-dark", app: app)
        app.terminate(); app = launch(reset: false, extra: ["--review-large"])
        capture("LensDesk-Today-large", app: app)
        app.buttons["open-profile"].tap(); app.buttons["open-settings"].tap(); app.buttons["edit-study-preferences"].tap()
        capture("LensDesk-Setup-large", app: app)
        reveal(app.buttons["12th grade"], app: app); app.buttons["12th grade"].tap()
        reveal(app.buttons["setup-continue"], app: app); app.buttons["setup-continue"].tap()
        capture("LensDesk-Route-large", app: app)
        app.buttons["setup-back"].tap()
        app.navigationBars.buttons["Cancel"].tap()
        capture("Student-Settings-large", app: app)
        app.navigationBars.buttons["Done"].tap()
        capture("LensDesk-Profile-large", app: app)
    }

    func testLensDeskEditDeleteAndMotionControl() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["daily-focus-lens"].exists)
        XCTAssertFalse(app.buttons["Pause 3D motion"].exists)
        app.buttons["daily-focus-lens"].tap()
        XCTAssertTrue(app.buttons["Start Focus"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["intake-paste"].tap()
        app.textFields["material-title"].tap(); app.textFields["material-title"].typeText("Editable class notes")
        app.buttons["save-material"].tap()
        XCTAssertTrue(app.staticTexts["import-error"].waitForExistence(timeout: 3))
        app.textViews["material-source-text"].tap(); app.textViews["material-source-text"].typeText("A source from class.")
        app.buttons["save-material"].tap()
        app.buttons["open-materials"].tap(); app.buttons["material-Editable class notes"].tap()
        app.buttons["edit-material"].tap()
        app.textViews["material-source-text"].tap(); app.textViews["material-source-text"].typeText(" Additional notes.")
        app.buttons["save-material"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Additional notes.")).firstMatch.waitForExistence(timeout: 3))
        app.buttons["Material actions"].tap(); app.buttons["Delete material"].tap()
        app.sheets.buttons["Delete material"].tap()
        XCTAssertTrue(app.staticTexts["Bring your classwork here."].waitForExistence(timeout: 4))
        capture("LensDesk-Empty-materials", app: app)
    }

    func testLensDeskSystemReducedMotion() throws {
        try XCTSkipUnless(UIAccessibility.isReduceMotionEnabled, "Run with iOS Reduce Motion enabled.")
        let app = launch()
        XCTAssertTrue(app.buttons["daily-focus-lens"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Pause 3D motion"].exists)
        app.buttons["open-profile"].tap(); app.buttons["open-settings"].tap(); app.buttons["edit-study-preferences"].tap()
        let core = app.descendants(matching: .any).matching(identifier: "setup-lens").firstMatch
        XCTAssertTrue(core.waitForExistence(timeout: 3))
        XCTAssertTrue((core.value as? String)?.contains("motion off") == true)
        capture("LensDesk-System-reduced-motion", app: app)
    }

    func testCourseCollection() throws {
        let app = launch()
        capture("Collection-Today", app: app)
        app.tabBars.buttons["Library"].tap()
        XCTAssertTrue(app.staticTexts["U.S. History"].firstMatch.waitForExistence(timeout: 4))
        capture("Collection-Library", app: app)
        app.staticTexts["U.S. History"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Course outline"].waitForExistence(timeout: 4))
        capture("Collection-Course", app: app)
        app.buttons["inspect-course-image"].tap()
        XCTAssertTrue(app.navigationBars["Behind the image"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["The Constitution, 1787"].exists)
        capture("Collection-Image-record", app: app)
        app.navigationBars.buttons["Done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        // Setup already adds the selected starting course to the student's shelf.
        app.buttons["save-first-state-civics"].tap()
        XCTAssertTrue(app.staticTexts["Course removed"].waitForExistence(timeout: 3))
        app.buttons["save-first-state-civics"].tap()
        XCTAssertTrue(app.staticTexts["Course saved"].waitForExistence(timeout: 3))
        app.buttons["Show saved courses"].tap()
        XCTAssertTrue(app.buttons["course-first-state-civics"].exists)
        XCTAssertFalse(app.buttons["course-algebra-i"].exists)
        app.terminate()
        let resumed = launch(reset: false)
        resumed.tabBars.buttons["Library"].tap()
        resumed.buttons["Show saved courses"].tap()
        XCTAssertTrue(resumed.buttons["course-first-state-civics"].waitForExistence(timeout: 3))
        resumed.tabBars.buttons["Explore"].tap()
        reveal(resumed.buttons["image-credits"], app: resumed)
        resumed.buttons["image-credits"].tap()
        let search = resumed.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 4))
        search.tap(); search.typeText("microscopy")
        // Search matches course, title, creator, institution, and medium.
        search.buttons["Clear text"].tap()
        search.typeText("Kateryna")
        XCTAssertTrue(resumed.buttons["credit-cells"].waitForExistence(timeout: 3))
        capture("Collection-Credits-search", app: resumed)
        resumed.buttons["credit-cells"].tap()
        XCTAssertTrue(resumed.staticTexts["Kateryna Kot"].waitForExistence(timeout: 3))
        capture("Collection-Microscopy-record", app: resumed)
    }

    func testFiveUnitInteractivePracticeAndPersistence() throws {
        let app = launch()
        app.tabBars.buttons["Library"].tap()
        let search = app.textFields["course-search"]
        search.tap(); search.typeText("Geometry\n")
        app.buttons["course-geometry"].tap()
        XCTAssertTrue(app.staticTexts["5 units · 30 activities"].waitForExistence(timeout: 4))
        capture("Study-Course-iPhone14", app: app)
        app.buttons["continue-unit-study"].tap()
        XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Angle relationships"].waitForExistence(timeout: 5))
        capture("Study-Offline-reading", app: app)
        startBitePractice(app)
        XCTAssertTrue(app.buttons["check-choice-vertical"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.buttons["enable-lesson-focus"].exists)
        app.buttons["check-choice-180"].tap(); app.buttons["check-answer"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["answer-incorrect"].waitForExistence(timeout: 3))
        capture("Practice-Try-again", app: app)
        app.buttons["check-answer"].tap()
        app.buttons["check-choice-vertical"].tap(); app.buttons["check-answer"].tap()
        capture("Practice-Correct", app: app)
        app.buttons["check-answer"].tap()
        let blank = app.textFields["blank-answer"]
        XCTAssertTrue(blank.waitForExistence(timeout: 3))
        blank.tap(); blank.typeText("180\n")
        XCTAssertTrue(app.descendants(matching: .any)["answer-correct"].waitForExistence(timeout: 3))
        app.buttons["check-answer"].tap()
        capture("Practice-Match", app: app)
        for (index, term) in ["vertical", "180", "adjacent"].enumerated() {
            let token = app.buttons["match-term-\(term)"]
            let slot = app.buttons["match-slot-\(index)"]
            reveal(token, app: app)
            if index == 0 {
                token.press(forDuration: 0.6, thenDragTo: slot)
            } else {
                token.tap()
                reveal(slot, app: app)
                slot.tap()
            }
            if index < 2 { app.swipeDown() }
        }
        app.buttons["check-answer"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["answer-correct"].waitForExistence(timeout: 3))
        app.buttons["check-answer"].tap(); app.buttons["check-answer"].tap()
        XCTAssertTrue(app.staticTexts["practice-saved"].waitForExistence(timeout: 3))
        capture("Practice-Complete", app: app)
        app.terminate()
        let resumed = launch(reset: false)
        resumed.buttons["Your profile"].tap()
        XCTAssertTrue(resumed.staticTexts["20 XP · 0-day practice streak"].waitForExistence(timeout: 3))
        capture("Study-XP-profile", app: resumed)
        resumed.navigationBars.buttons.element(boundBy: 0).tap()
        resumed.tabBars.buttons["Library"].tap()
        let again = resumed.textFields["course-search"]
        again.tap(); again.typeText("Geometry\n")
        resumed.buttons["course-geometry"].tap()
        XCTAssertTrue(resumed.staticTexts["2 studied"].waitForExistence(timeout: 3))
        resumed.buttons["continue-unit-study"].tap()
        XCTAssertTrue(resumed.staticTexts["Parallel lines and transversals"].waitForExistence(timeout: 5))
    }

    func testLocalIdentityAndCircularHeader() throws {
        let app = launch()
        let profile = app.buttons["open-profile"]
        XCTAssertTrue(profile.waitForExistence(timeout: 4))
        XCTAssertLessThanOrEqual(profile.frame.width, 60)
        XCTAssertLessThan(abs(profile.frame.width-profile.frame.height), 8)
        XCTAssertFalse(app.staticTexts["first state"].exists)
        capture("Identity-Today-header", app: app)
        app.swipeUp(); app.swipeUp()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 3))
        let compactProfile = app.navigationBars.buttons["open-profile"]
        XCTAssertTrue(compactProfile.isHittable)
        capture("Identity-Compact-header", app: app)
        compactProfile.tap()
        XCTAssertTrue(app.staticTexts["Avery"].waitForExistence(timeout: 3))
        capture("Identity-Profile", app: app)
        signOut(app)
        let password = app.secureTextFields["profile-password"]
        XCTAssertTrue(password.waitForExistence(timeout: 3))
        password.tap(); password.typeText("IncorrectPassword42\n")
        XCTAssertTrue(app.staticTexts["identity-error"].waitForExistence(timeout: 4))
        capture("Identity-Wrong-password", app: app)
        password.tap(); password.typeText("StudyTestOnly42\n")
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        app.terminate()
        let resumed = launch(reset: false)
        XCTAssertTrue(resumed.buttons["open-profile"].exists)
    }

    func testAccountChoicesAndFullLocalReset() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-test-data", "--seed-level"]
        app.launch()
        let modes = app.segmentedControls["auth-mode"]
        XCTAssertTrue(modes.waitForExistence(timeout: 5))
        XCTAssertTrue(modes.buttons["Create account"].isSelected)
        capture("Account-Create-choice", app: app)
        func credentials(_ name: String) {
            let username = app.textFields["onboarding-name"]
            if (username.value as? String) != name {
                username.tap()
                if let current = username.value as? String, current != "e.g. orbit_student" {
                    username.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
                }
                username.typeText(name)
            }
            let password = app.secureTextFields["profile-password"]
            password.tap(); password.typeText("StudyTestOnly42\n")
        }
        modes.buttons["Log in"].tap()
        credentials("NewStudent")
        XCTAssertTrue(app.staticTexts["identity-error"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["identity-error"].label.contains("No account"))
        capture("Account-No-saved-account", app: app)
        modes.buttons["Create account"].tap()
        credentials("NewStudent")
        app.buttons["start-learning"].tap()
        finishSetupIfNeeded(app)
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        app.buttons["open-profile"].tap()
        XCTAssertTrue(app.staticTexts["90 XP · 0-day practice streak"].waitForExistence(timeout: 3))
        signOut(app)
        XCTAssertTrue(modes.waitForExistence(timeout: 3))
        modes.buttons["Create account"].tap()
        credentials("newstudent")
        app.buttons["start-learning"].tap()
        XCTAssertTrue(app.staticTexts["identity-error"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["identity-error"].label.contains("username is taken"))
        modes.buttons["Log in"].tap(); credentials("NewStudent")
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        app.terminate()
        // This flag must clear only the isolated test credential, progress, and avatars.
        app.launchArguments = ["--ui-testing", "--reset-local-account"]
        app.launch()
        XCTAssertTrue(modes.waitForExistence(timeout: 5))
        XCTAssertTrue(modes.buttons["Create account"].isSelected)
        XCTAssertFalse(app.buttons["start-learning"].isEnabled)
        modes.buttons["Log in"].tap(); credentials("NewStudent")
        XCTAssertTrue(app.staticTexts["identity-error"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["identity-error"].label.contains("No account"))
        modes.buttons["Create account"].tap(); credentials("FreshStudent")
        app.buttons["start-learning"].tap()
        finishSetupIfNeeded(app)
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        app.buttons["open-profile"].tap()
        XCTAssertTrue(app.staticTexts["0 XP · 0-day practice streak"].waitForExistence(timeout: 3))
        capture("Account-Reset-empty-profile", app: app)
    }

    func testAccountChoiceAppearance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-test-data", "--review-large"]
        app.launch()
        let modes = app.segmentedControls["auth-mode"]
        XCTAssertTrue(modes.waitForExistence(timeout: 5))
        capture("Account-Create-large", app: app)
        modes.buttons["Log in"].tap()
        XCTAssertTrue(app.staticTexts["Back to your studies."].waitForExistence(timeout: 3))
        reveal(app.buttons["start-learning"], app: app)
        capture("Account-Login-large", app: app)
        app.terminate()
        app.launchArguments = ["--ui-testing", "--review-dark"]
        app.launch()
        XCTAssertTrue(modes.waitForExistence(timeout: 5))
        capture("Account-Create-dark", app: app)
        modes.buttons["Log in"].tap()
        XCTAssertTrue(app.secureTextFields["profile-password"].waitForExistence(timeout: 3))
        capture("Account-Login-dark", app: app)
    }

    func testMultipleAccountsKeepStudyDataSeparate() throws {
        var app = launch(extra: ["--seed-level"])
        func accountEntry(_ name: String, create: Bool, password: String = "StudyTestOnly42") {
            let modes = app.segmentedControls["auth-mode"]
            XCTAssertTrue(modes.waitForExistence(timeout: 4))
            modes.buttons[create ? "Create account" : "Log in"].tap()
            let field = app.textFields["onboarding-name"]
            if (field.value as? String) != name {
                field.tap()
                if let value = field.value as? String, value != "e.g. orbit_student" {
                    field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
                }
                field.typeText(name)
            }
            app.secureTextFields["profile-password"].tap(); app.secureTextFields["profile-password"].typeText(password + "\n")
            if create { reveal(app.buttons["start-learning"], app: app); app.buttons["start-learning"].tap(); finishSetupIfNeeded(app) }
        }
        func logOut() {
            app.tabBars.buttons["Today"].tap(); app.buttons["open-profile"].tap()
            signOut(app)
        }
        app.tabBars.buttons["Plan"].tap(); app.buttons["new-task"].tap()
        app.textFields["task-title"].tap(); app.textFields["task-title"].typeText("Avery private task\n")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Edit Avery private task"].waitForExistence(timeout: 3))
        logOut()
        accountEntry("Morgan", create: true, password: "MorganTestOnly42")
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.staticTexts["No open tasks"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Edit Avery private task"].exists)
        app.buttons["new-task"].tap()
        app.textFields["task-title"].tap(); app.textFields["task-title"].typeText("Morgan private task\n")
        app.buttons["Save"].tap()
        app.tabBars.buttons["Today"].tap(); app.buttons["open-profile"].tap()
        XCTAssertTrue(app.staticTexts["Morgan"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["0 XP · 0-day practice streak"].exists)
        capture("Multi-Morgan-profile", app: app)
        signOut(app)
        accountEntry("Avery", create: false, password: "MorganTestOnly42")
        XCTAssertTrue(app.staticTexts["identity-error"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.tabBars.buttons["Today"].exists)
        accountEntry("avery", create: false)
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.buttons["Edit Avery private task"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Edit Morgan private task"].exists)
        capture("Multi-Avery-plan", app: app)
        app.tabBars.buttons["Today"].tap(); app.buttons["open-profile"].tap()
        XCTAssertTrue(app.staticTexts["90 XP · 0-day practice streak"].waitForExistence(timeout: 3))
        app.terminate()
        app = XCUIApplication(); app.launchArguments = ["--ui-testing"]; app.launch()
        accountEntry("Morgan", create: false, password: "MorganTestOnly42")
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.buttons["Edit Morgan private task"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Edit Avery private task"].exists)
        capture("Multi-Morgan-restored", app: app)
        logOut()
        accountEntry("ThirdStudent", create: true)
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.staticTexts["No open tasks"].waitForExistence(timeout: 3))
    }

    func testLegacyCredentialAndProgressMigration() throws {
        let app = launch(extra: ["--seed-legacy-account", "--seed-level"])
        app.buttons["open-profile"].tap()
        XCTAssertTrue(app.staticTexts["90 XP · 0-day practice streak"].waitForExistence(timeout: 3))
        capture("Multi-Legacy-progress", app: app)
        signOut(app)
        app.terminate()
        let resumed = launch(reset: false)
        resumed.buttons["open-profile"].tap()
        XCTAssertTrue(resumed.staticTexts["90 XP · 0-day practice streak"].waitForExistence(timeout: 3))
    }

    func testInteractiveQuestionResumeAndLargeLayout() throws {
        var app = launch()
        func openGeometry(_ app: XCUIApplication) {
            app.tabBars.buttons["Library"].tap()
            app.textFields["course-search"].tap(); app.textFields["course-search"].typeText("Geometry\n")
            app.buttons["course-geometry"].tap(); app.buttons["continue-unit-study"].tap()
        }
        openGeometry(app)
        startBitePractice(app)
        XCTAssertTrue(app.buttons["check-choice-vertical"].waitForExistence(timeout: 4))
        app.buttons["check-choice-vertical"].tap(); app.buttons["check-answer"].tap(); app.buttons["check-answer"].tap()
        XCTAssertTrue(app.textFields["blank-answer"].waitForExistence(timeout: 3))
        app.terminate()
        app = launch(reset: false, extra: ["--review-dark", "--review-large"])
        openGeometry(app)
        XCTAssertTrue(app.textFields["blank-answer"].waitForExistence(timeout: 4))
        capture("Practice-Resumed-large", app: app)
        app.textFields["blank-answer"].tap(); app.textFields["blank-answer"].typeText("180\n")
        XCTAssertTrue(app.descendants(matching: .any)["answer-correct"].waitForExistence(timeout: 3))
        capture("Practice-Feedback-large", app: app)
    }

    func testProfilePhotoPickerAndPersistence() throws {
        let app = launch()
        app.buttons["Your profile"].tap()
        app.buttons["edit-profile-photo"].tap()
        app.buttons["choose-profile-photo"].tap()
        // The Simulator is seeded with one real, bundled microscopy image.
        let picker = app.otherElements["Photos"].firstMatch
        _ = picker.waitForExistence(timeout: 3)
        capture("Study-Photo-picker", app: app)
        let photo = app.images.matching(NSPredicate(format: "label BEGINSWITH %@", "Photo,")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 5))
        photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Remove photo"].waitForExistence(timeout: 8))
        app.navigationBars.buttons["Done"].tap()
        capture("Study-Photo-profile", app: app)
        app.terminate()
        let resumed = launch(reset: false)
        resumed.buttons["Your profile"].tap()
        resumed.buttons["edit-profile-photo"].tap()
        XCTAssertTrue(resumed.buttons["Remove photo"].waitForExistence(timeout: 4))
        resumed.buttons["Remove photo"].tap()
        XCTAssertFalse(resumed.buttons["Remove photo"].exists)
    }

    func testLevelArrivalUsesEarnedStudyXP() throws {
        let app = launch(extra: ["--seed-level"])
        app.tabBars.buttons["Library"].tap()
        app.textFields["course-search"].tap(); app.textFields["course-search"].typeText("Geometry\n")
        app.buttons["course-geometry"].tap(); app.buttons["continue-unit-study"].tap()
        startBitePractice(app)
        XCTAssertTrue(app.staticTexts["Level 2 reached"].waitForExistence(timeout: 3))
        capture("Study-Earned-level-arrival", app: app)
    }

    func testBackgroundSoundAndLockScreenTimer() throws {
        let app = launch()
        app.tabBars.buttons["Explore"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Focus & Zen")).firstMatch.tap()
        let task = app.textFields["Session task"]
        task.tap(); task.typeText("Read and recall membrane transport\n")
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Study sounds")).firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Brown noise,")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Playing · tap to pause"].waitForExistence(timeout: 8))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.swipeDown()
        app.buttons["Start Focus"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let top = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.005))
        top.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.8)))
        if springboard.buttons["Always Allow"].exists { springboard.buttons["Always Allow"].tap() }
        else if springboard.buttons["Allow"].exists { springboard.buttons["Allow"].tap() }
        capture("Study-Lock-Screen-timer-and-audio", app: springboard)
        XCTAssertTrue(springboard.staticTexts["Read and recall membrane transport"].waitForExistence(timeout: 5))
        // Now Playing can be in Control Center rather than the notification stack.
        if !springboard.staticTexts["Brown noise"].exists {
            XCUIDevice.shared.press(.home)
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.005)).press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.8)))
            capture("Study-Background-audio-controls", app: springboard)
        }
        // This runtime can expose an empty Control Center module tree. Do not
        // substitute a passing in-app test for a real-device remote-command test.
        if springboard.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Brown noise")).firstMatch.exists {
            capture("Study-System-Now-Playing", app: springboard)
        }
        app.activate()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 4))
        let sounds = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Study sounds")).firstMatch
        reveal(sounds, app: app); sounds.tap()
        XCTAssertTrue(app.staticTexts["Playing · tap to pause"].waitForExistence(timeout: 4))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Brown noise,")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Paused · tap to resume"].waitForExistence(timeout: 3))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Brown noise,")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Playing · tap to pause"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.swipeDown()
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 3))
        app.terminate()
        let resumed = launch(reset: false)
        resumed.tabBars.buttons["Explore"].tap()
        resumed.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Focus & Zen")).firstMatch.tap()
        XCTAssertTrue(resumed.buttons["Resume"].waitForExistence(timeout: 3))
        capture("Study-Paused-timer-relaunch", app: resumed)
    }

    func testOfflineMathDiagramsAndReadingReturn() throws {
        let app = launch()
        app.tabBars.buttons["Library"].tap()
        app.buttons["All"].tap()
        app.textFields["course-search"].tap(); app.textFields["course-search"].typeText("College Algebra\n")
        app.buttons["course-college-algebra"].tap()
        app.segmentedControls.buttons["Resources"].tap()
        app.buttons["resources-readings"].tap()
        let chapter = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "resource-reading-")).firstMatch
        chapter.tap()
        let reader = app.webViews.firstMatch
        XCTAssertTrue(reader.waitForExistence(timeout: 5))
        capture("Study-Textbook-opening", app: app)
        reader.swipeUp(); reader.swipeUp(); reader.swipeUp()
        let definition = reader.staticTexts["Function"].firstMatch
        XCTAssertTrue(definition.isHittable)
        capture("Study-Math-and-diagrams", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        chapter.tap()
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 4))
        let restored = app.webViews.firstMatch.staticTexts["Function"].firstMatch
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: restored)
        XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 5), .completed)
        capture("Study-Reading-position-restored", app: app)
    }

    func testOneMinuteFocusEndsAfterBackgrounding() throws {
        let app = launch(extra: ["--short-focus"])
        app.tabBars.buttons["Explore"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Focus & Zen")).firstMatch.tap()
        app.buttons["Start Focus"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 4))
        XCUIDevice.shared.press(.home)
        // Two bounded waits keep the test runner responsive and check the app
        // remains backgrounded. This is one minute, not a long-run device audit.
        for interval in 0..<2 {
            let elapsed = expectation(description: "Background interval \(interval)")
            DispatchQueue.main.asyncAfter(deadline: .now()+31) { elapsed.fulfill() }
            wait(for: [elapsed], timeout: 35)
            XCTAssertNotEqual(app.state, .runningForeground)
        }
        app.activate()
        XCTAssertTrue(app.staticTexts["Interval complete"].waitForExistence(timeout: 5))
        capture("Study-One-minute-background-completion", app: app)
        let sounds = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Study sounds")).firstMatch
        reveal(sounds, app: app); sounds.tap()
        XCTAssertFalse(app.staticTexts["Playing · tap to pause"].exists)
        XCTAssertFalse(app.buttons["Stop sound"].isEnabled)
    }

    func testDarkReaderAndGentleReset() throws {
        let app = launch(extra: ["--review-dark"])
        app.tabBars.buttons["Library"].tap()
        app.buttons["All"].tap()
        app.textFields["course-search"].tap(); app.textFields["course-search"].typeText("College Algebra\n")
        app.buttons["course-college-algebra"].tap(); app.buttons["continue-unit-study"].tap()
        XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 4))
        capture("Study-Reader-dark", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Explore"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Focus & Zen")).firstMatch.tap()
        let reset = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "One-minute reset")).firstMatch
        reveal(reset, app: app); reset.tap()
        app.buttons["Start reset"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label IN %@", ["Breathe in", "Breathe out"])).firstMatch.waitForExistence(timeout: 3))
        capture("Study-Gentle-reset", app: app)
        app.buttons["Stop reset"].tap()
        XCTAssertTrue(app.staticTexts["Ready"].waitForExistence(timeout: 3))
    }

    func testPersonalFinanceReadingAndProfileLayout() throws {
        let app = launch(reset: false)
        app.tabBars.buttons["Library"].tap()
        app.textFields["course-search"].tap(); app.textFields["course-search"].typeText("Personal Finance\n")
        app.buttons["course-personal-finance"].tap()
        app.buttons["continue-unit-study"].tap()
        XCTAssertTrue(app.staticTexts["Build a cash-flow budget"].waitForExistence(timeout: 5))
        capture("Study-Personal-finance-reader", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Today"].tap()
        app.buttons["Your profile"].tap()
        XCTAssertTrue(app.buttons["edit-profile-photo"].waitForExistence(timeout: 3))
        capture("Study-Profile-layout", app: app)
    }

    func testTodayConnectsUnitStudyAndFocus() throws {
        let app = launch()
        app.buttons["continue-unit-study-home"].tap()
        XCTAssertTrue(app.staticTexts["lesson-step-body"].waitForExistence(timeout: 5))
        app.buttons["Focus on this reading"].tap()
        let task = app.textFields["Session task"]
        XCTAssertTrue(task.waitForExistence(timeout: 4))
        XCTAssertTrue((task.value as? String ?? "").contains("Portuguese"))
        capture("Study-Reading-linked-Focus", app: app)
    }

    func testSearchAndCourseContext() throws {
        let app = launch()
        app.tabBars.buttons["Library"].tap()
        let search = app.textFields["course-search"]
        search.tap(); search.typeText("Chemistry\n")
        XCTAssertTrue(app.buttons["course-general-chemistry"].waitForExistence(timeout: 3))
        app.buttons["College"].tap()
        capture("Collection-Chemistry", app: app)
        app.buttons["course-general-chemistry"].tap()
        XCTAssertTrue(app.buttons["inspect-course-image"].waitForExistence(timeout: 3))
        app.buttons["inspect-course-image"].tap()
        XCTAssertTrue(app.staticTexts["Measuring a chemical amount"].waitForExistence(timeout: 3))
        capture("Collection-Technical-image", app: app)
        app.navigationBars.buttons["Done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertEqual(search.value as? String, "Chemistry")
        XCTAssertTrue(app.buttons["College"].isSelected)
        app.buttons["Clear search"].tap()
        app.buttons["All"].tap()
        search.tap(); search.typeText("computer\n")
        XCTAssertTrue(app.buttons["course-computer-science"].waitForExistence(timeout: 3))
        capture("Collection-Computing", app: app)
        app.buttons["course-computer-science"].tap()
        app.buttons["inspect-course-image"].tap()
        XCTAssertTrue(app.staticTexts["Instructions made physical"].waitForExistence(timeout: 3))
        capture("Collection-Loom-record", app: app)
    }

    func testLessonNotesReviewAndPersistence() throws {
        let app = launch()
        capture("Today", app: app)
        app.buttons["lesson-course-outline"].tap()
        reveal(app.buttons["course-study-next"], app: app); app.buttons["course-study-next"].tap()
        XCTAssertTrue(app.buttons["Your note"].waitForExistence(timeout: 3))
        app.buttons["Your note"].tap()
        let editor = app.textViews["Your lesson note"]
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap(); editor.typeText("Separate what the petition says from later context.")
        app.navigationBars.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Your note"].waitForExistence(timeout: 3))
        let practice = app.buttons["Practice this lesson"]
        reveal(practice, app: app); capture("Lesson", app: app); practice.tap()
        XCTAssertTrue(app.staticTexts["When was the petition written?"].waitForExistence(timeout: 4))
        app.buttons["Bookmark question"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "July 4, 1776")).firstMatch.tap()
        app.buttons["Check my reasoning"].tap()
        XCTAssertTrue(app.staticTexts["Not quite"].waitForExistence(timeout: 3))
        capture("Practice-feedback", app: app)
        reveal(app.buttons["Continue"], app: app); app.buttons["Continue"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "A lack of an efficient general government")).firstMatch.tap()
        app.buttons["Check my reasoning"].tap()
        reveal(app.buttons["Finish session"], app: app); app.buttons["Finish session"].tap()
        XCTAssertTrue(app.buttons["Return home"].waitForExistence(timeout: 3))
        app.buttons["Return home"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Review"].tap()
        XCTAssertTrue(app.staticTexts["When was the petition written?"].waitForExistence(timeout: 3))
        capture("Review", app: app)
        app.segmentedControls.buttons["Notes"].tap()
        XCTAssertTrue(app.staticTexts["Read the record"].waitForExistence(timeout: 3))
        capture("Notes", app: app)
        app.terminate()
        let resumed = launch(reset: false)
        resumed.tabBars.buttons["Review"].tap()
        resumed.segmentedControls.buttons["Notes"].tap()
        XCTAssertTrue(resumed.staticTexts["Separate what the petition says from later context."].waitForExistence(timeout: 3))
    }

    func testPlannerFocusZenAndCatalog() throws {
        let app = launch()
        app.tabBars.buttons["Plan"].tap()
        app.buttons["new-task"].tap()
        let title = app.textFields["task-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tap(); title.typeText("Review cell transport")
        app.navigationBars.buttons["save-task"].tap()
        XCTAssertTrue(app.buttons["Edit Review cell transport"].waitForExistence(timeout: 3))
        app.buttons["Edit Review cell transport"].tap()
        let edit = app.textFields["task-title"]
        app.buttons["Clear task title"].tap()
        edit.tap(); edit.typeText("Review cell transport today")
        app.navigationBars.buttons["save-task"].tap()
        capture("Planner", app: app)
        app.buttons["Focus on Review cell transport today"].tap()
        reveal(app.buttons["Start Focus"], app: app)
        app.buttons["Start Focus"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 3))
        app.buttons["Resume"].tap()
        capture("Focus", app: app)
        app.buttons["Enter Zen"].tap()
        XCTAssertTrue(app.buttons["Exit Zen"].waitForExistence(timeout: 4))
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in app.frame.width > app.frame.height }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 5), .completed)
        XCTAssertTrue(app.buttons["Exit Zen"].isHittable)
        capture("Zen-landscape", app: app)
        app.tap()
        app.buttons["Hide tasks"].tap()
        XCTAssertTrue(app.buttons["Show tasks"].exists)
        app.buttons["Exit Zen"].tap()
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        app.terminate()
        let resumed = launch(reset: false)
        resumed.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(resumed.buttons["Edit Review cell transport today"].waitForExistence(timeout: 3))
        resumed.buttons["Focus on Review cell transport today"].tap()
        XCTAssertTrue(resumed.buttons["Pause"].waitForExistence(timeout: 3))
        resumed.buttons["End session"].tap()
        resumed.buttons["End and save time"].tap()
        XCTAssertTrue(resumed.buttons["Start Focus"].waitForExistence(timeout: 3))
        resumed.tabBars.buttons["Library"].tap()
        capture("Library", app: resumed)
        resumed.buttons["AP preparation"].tap()
        XCTAssertTrue(resumed.buttons["course-prep-biology"].waitForExistence(timeout: 3))
    }

    func testExploreAndVisualLayouts() throws {
        let app = launch()
        app.tabBars.buttons["Library"].tap()
        app.swipeUp()
        XCTAssertTrue(app.navigationBars.staticTexts["Library"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.navigationBars.staticTexts["Library"].isHittable)
        capture("Library-compact-header", app: app)
        app.tabBars.buttons["Explore"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Your profile")).firstMatch.tap()
        capture("Profile", app: app)
        let all = app.buttons["See all"]
        reveal(all, app: app); all.tap()
        capture("Achievements", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "My school")).firstMatch.tap()
        app.buttons["Choose school (optional)"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.tap(); search.typeText("Dover")
        capture("School-directory", app: app)
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Dover High School")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Change or remove school"].waitForExistence(timeout: 3))
        capture("School-workspace", app: app)
    }

    func testAppearanceReviews() throws {
        var app = launch()
        app.terminate()
        app = launch(reset: false, extra: ["--review-dark"])
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 4))
        capture("Today-dark", app: app)
        app.tabBars.buttons["Library"].tap()
        capture("Library-dark", app: app)
        app.tabBars.buttons["Explore"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Study circle")).firstMatch.tap()
        capture("Community-dark", app: app)
        app.terminate()
        app = launch(reset: false, extra: ["--review-large"])
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 4))
        capture("Today-larger-text", app: app)
        app.tabBars.buttons["Library"].tap()
        capture("Library-larger-text", app: app)
        app.tabBars.buttons["Plan"].tap()
        app.buttons["new-task"].tap()
        XCTAssertTrue(app.textFields["task-title"].waitForExistence(timeout: 3))
        app.textFields["task-title"].tap()
        app.textFields["task-title"].typeText("Review lab notes")
        capture("Task-editor-larger-text", app: app)
    }

    func testSoundPlaybackAndCollegePlanning() throws {
        let app = launch()
        app.tabBars.buttons["Explore"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Sound studio")).firstMatch.tap()
        let pink = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Pink noise,")).firstMatch
        XCTAssertTrue(pink.waitForExistence(timeout: 3))
        pink.tap()
        XCTAssertTrue(app.buttons["Pink noise, pause"].waitForExistence(timeout: 10))
        app.buttons["Favorite Pink noise"].tap()
        capture("Sound-studio-playing", app: app)
        let stop = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Stop sound")).firstMatch
        reveal(stop, app: app); stop.tap()
        XCTAssertTrue(app.buttons["Pink noise, preview and select"].exists)
        app.buttons["Research and sources"].tap()
        capture("Sound-research", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "College & next steps")).firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Explore fields of study")).firstMatch.tap()
        capture("College", app: app)
        let field = app.textFields["college-routes"]
        reveal(field, app: app); field.tap(); field.typeText("Engineering and community college transfer")
        app.terminate()
        let resumed = launch(reset: false)
        resumed.tabBars.buttons["Explore"].tap()
        resumed.buttons.matching(NSPredicate(format: "label CONTAINS %@", "College & next steps")).firstMatch.tap()
        let restored = resumed.textFields["college-routes"]
        XCTAssertTrue(restored.waitForExistence(timeout: 3))
        XCTAssertEqual(restored.value as? String, "Engineering and community college transfer")
    }
}
