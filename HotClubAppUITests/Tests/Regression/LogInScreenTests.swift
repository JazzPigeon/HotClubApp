//
//  LogInScreenTests.swift
//  HotClubApp
//
//  Created by Cindy Michalowski on 6/2/26.
//

import XCTest

class LogInScreenTests: BaseTest {
    
    // Use this to override auth bypass in Regression test plan for noe
    // May need a separate “UI test auth mode” later if a persisted auth session
    // causes the Log In screen to be skipped during testing
    override var usesMockDataLayer: Bool {
            false
        }
    
    func test_tapSignInButton() throws {
        
        LogInScreen()
            .assertSignInButtonIsDisabled()
    }

    // Excluded in Test Plan; used for testing reporting
    func test_thisTestShouldFail() throws {
        LogInScreen()
            .assertPageTitleIsDisplayedAsExpected()
    }
}
