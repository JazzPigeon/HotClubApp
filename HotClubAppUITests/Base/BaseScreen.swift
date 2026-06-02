//
//  BaseScreen.swift
//  HotClubApp
//
//  Created by Cindy Michalowski on 6/8/26.
//

import XCTest

protocol BaseScreen {}

extension BaseScreen {

    func findAll(_ type: XCUIElement.ElementType) -> XCUIElementQuery {
        XCUIApplication().descendants(matching: type)
    }

    var buttons: XCUIElementQuery { findAll(.button) }
    var textFields: XCUIElementQuery { findAll(.textField) }
    var secureTextFields: XCUIElementQuery { findAll(.secureTextField) }
    var searchFields: XCUIElementQuery { findAll(.searchField) }
    var staticTexts: XCUIElementQuery { findAll(.staticText) }
    var textViews: XCUIElementQuery { findAll(.textView) }
    var images: XCUIElementQuery { findAll(.image) }
    var tables: XCUIElementQuery { findAll(.table) }
    var cells: XCUIElementQuery { findAll(.cell) }
    var collectionViews: XCUIElementQuery { findAll(.collectionView) }
    var navigationBars: XCUIElementQuery { findAll(.navigationBar) }
    var tabBars: XCUIElementQuery { findAll(.tabBar) }
    var toolbars: XCUIElementQuery { findAll(.toolbar) }
    var scrollViews: XCUIElementQuery { findAll(.scrollView) }
    var alerts: XCUIElementQuery { findAll(.alert) }
    var switches: XCUIElementQuery { findAll(.switch) }
    var sliders: XCUIElementQuery { findAll(.slider) }
    var pickers: XCUIElementQuery { findAll(.picker) }
    var otherElements: XCUIElementQuery { findAll(.other) }

    @discardableResult
    func waitForElementToAppear(waitForElement element: XCUIElement, waitForSeconds timeout: TimeInterval = 3) -> Bool {
        let existsPredicate = NSPredicate(format: "exists = true")
        let expectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: element)

        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
