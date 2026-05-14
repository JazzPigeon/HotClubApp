//
//  HotClubAppTests.swift
//  HotClubAppTests
//
//  Created by Cindy Michalowski on 10/13/25.
//

import Foundation
import Testing
@testable import HotClubApp

struct HotClubAppTests {

    @Test func catalogRecordRowDecodesFromSupabaseShape() throws {
        let json = """
        {
          "id": "123e4567-e89b-12d3-a456-426614174000",
          "created_at": "2025-01-01T12:00:00Z",
          "updated_at": "2025-01-01T12:30:00Z",
          "record_sides": [
            {
              "id": "123e4567-e89b-12d3-a456-426614174001",
              "record_id": "123e4567-e89b-12d3-a456-426614174000",
              "side": "A",
              "song_title": "Sweet Sue",
              "artist": "Bix",
              "composer": null,
              "label": "Okeh",
              "year": 1928,
              "image_storage_path": "user/rec/A.jpg"
            },
            {
              "id": "123e4567-e89b-12d3-a456-426614174002",
              "record_id": "123e4567-e89b-12d3-a456-426614174000",
              "side": "B",
              "song_title": "Copenhagen",
              "artist": "Bix",
              "composer": null,
              "label": "Okeh",
              "year": 1928,
              "image_storage_path": null
            }
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let row = try decoder.decode(CatalogRecordRow.self, from: json)
        #expect(row.id.uuidString.lowercased() == "123e4567-e89b-12d3-a456-426614174000")
        #expect(row.recordSides.count == 2)
        #expect(row.side(.A)?.songTitle == "Sweet Sue")
        #expect(row.side(.B)?.songTitle == "Copenhagen")
        #expect(row.side(.B)?.imageStoragePath == nil)
    }
}
