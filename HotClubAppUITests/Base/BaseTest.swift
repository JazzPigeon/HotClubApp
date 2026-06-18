//
//  BaseTest.swift
//  HotClubApp
//
//  Created by Cindy Michalowski on 6/2/26.
//

import XCTest

class BaseTest: XCTestCase {
    
    let app = XCUIApplication()
    
    var usesMockDataLayer: Bool {
        true
    }
    
    // if test fails, this flag is false and application exit is handled by TearDown()
    var testRanToCompletion: Bool = false
    
    // Set Up
    override func setUp() {
        
        // use to track whether test ran to completion; saves time during tear down in cases where test fails
        testRanToCompletion = false
                
        // if an assertion fails in the course of running a test, test will stop
        continueAfterFailure = false
        
        app.launchArguments += [
            "-disableAnimations",
            "-skipOnboarding"
        ]

        // Forward the mock-data flag from the test plan to the app under test.
        // Test plan environment variables apply to the test runner, not the app process,
        // so XCUITest requires forwarding them explicitly via launchEnvironment.
        if usesMockDataLayer,
           ProcessInfo.processInfo.environment["UITEST_MOCK"] == "1" {
            app.launchEnvironment["UITEST_MOCK"] = "1"
        }

        // launch the app under test
        app.launch()
    }
    
    // Tear Down
    override func tearDown() {
        // if test fails, capture screenshot at point of failure; delete tearDown screenshot if test passes
        let screenshot = XCUIScreen.main.screenshot()
        let fullScreenshotAttachment = XCTAttachment(screenshot: screenshot)
        fullScreenshotAttachment.lifetime = .deleteOnSuccess
        add(fullScreenshotAttachment)
                
        // in the event of a test failure, app needs to be exited gracefully to prevent all other tests from failing
//        if testRanToCompletion == false {
//
//        }
        
        // terminate app
        app.terminate()
    }
    
}
