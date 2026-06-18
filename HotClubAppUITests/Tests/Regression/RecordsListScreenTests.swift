//
//  RecordsListScreenTests.swift
//  HotClubApp
//
//  Created by Cindy Michalowski on 6/11/26.
//

import XCTest

class RecordsListScreenTests: BaseTest {

    func test_recordsListShowsSeededRecords() throws {
        RecordsListScreen()
            .assertRecordsListIsDisplayed()
            .assertRecordIsDisplayed(containing: RecordsListScreenStrings().seededRecordTitle)
    }
}
