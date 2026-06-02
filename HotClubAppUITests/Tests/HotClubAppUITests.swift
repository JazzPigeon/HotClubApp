//
//  HotClubAppUITests.swift
//  HotClubAppUITests
//
//  Created by Cindy Michalowski on 10/13/25.
//

import XCTest

final class HotClubAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsRootFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let setup = app.navigationBars["Setup"].waitForExistence(timeout: 8)
        let auth = app.navigationBars["78 rpm catalog"].waitForExistence(timeout: 8)
        let tabs = app.tabBars.firstMatch.waitForExistence(timeout: 8)

        print("Wait here")
        
        XCTAssertTrue(
            setup || auth || tabs,
            "Expected setup (missing secrets), sign-in, or main tab bar after launch."
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
