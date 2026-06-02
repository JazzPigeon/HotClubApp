//
//  LogInScreenTests.swift
//  HotClubApp
//
//  Created by Cindy Michalowski on 6/2/26.
//

import XCTest

class LogInScreenTests: BaseTest {
    
    func test_tapSignInButton() throws {
        
        LogInScreen()
            .assertSignInButtonIsDisabled()
    }
}
