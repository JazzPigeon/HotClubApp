//
//  SettingsMenu.swift
//  HotClubApp
//
//  Created by Cindy Michalowski on 6/10/26.
//

import XCTest

class SettingsMenu: BaseScreen {
    
    private let strings = SettingsMenuStrings()
    
    // MARK: Element locators
    lazy var btnSignOut = buttons[strings.signOut].firstMatch
    
    // MARK: Actions
    @discardableResult
    func tapSignOutButton() -> SettingsMenu {
        waitForElementToAppear(waitForElement: btnSignOut)
        btnSignOut.tap()
        return self
    }
}
