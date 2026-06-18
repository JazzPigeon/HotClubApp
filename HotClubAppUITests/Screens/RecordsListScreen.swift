//
//  RecordsListScreen.swift
//  HotClubApp
//
//  Created by Cindy Michalowski on 6/11/26.
//

import XCTest

class RecordsListScreen: BaseScreen {

    private let strings = RecordsListScreenStrings()

    // MARK: Element locators
    lazy var navBar = navigationBars[strings.title]

    // MARK: Assertions
    @discardableResult
    func assertRecordsListIsDisplayed() -> RecordsListScreen {
        XCTAssertTrue(
            waitForElementToAppear(waitForElement: navBar, waitForSeconds: 10),
            "Records list should be displayed after login is bypassed in mock mode."
        )
        return self
    }

    @discardableResult
    func assertRecordIsDisplayed(containing text: String) -> RecordsListScreen {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        let element = staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(
            waitForElementToAppear(waitForElement: element, waitForSeconds: 10),
            "Expected a mocked record containing '\(text)' to be displayed."
        )
        return self
    }
}
