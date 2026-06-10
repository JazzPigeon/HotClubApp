//
//  LogInScreen.swift
//  HotClubApp
//
//  Created by Cindy Michalowski on 6/8/26.
//

import XCTest

class LogInScreen: BaseScreen {

    private let strings = LoginScreenStrings()

    // MARK: Element locators
    lazy var txtTitle = staticTexts[strings.title]
    lazy var txtFieldEmail = textFields[strings.email]
    lazy var txtFieldPassword = secureTextFields[strings.password]
    lazy var btnSignIn = buttons.matching(identifier: strings.signIn).element(boundBy: 0)
    
    // MARK: Actions
    @discardableResult
    func tapSignInButton() -> LogInScreen {
        waitForElementToAppear(waitForElement: btnSignIn)
        btnSignIn.tap()
        return self
    }
    
    // MARK: Assertions
    @discardableResult
    func assertPageTitleIsDisplayedAsExpected() -> LogInScreen {
        XCTAssertEqual(txtTitle.value as! String, "78 rpm catalog", "App title is displayed as '78 rpm catalog'")
        return self
    }

    @discardableResult
    func assertSignInButtonIsDisabled() -> LogInScreen {
        XCTAssert(!btnSignIn.isEnabled, "Sign in button is disabled as expected")
        return self
    }
}
