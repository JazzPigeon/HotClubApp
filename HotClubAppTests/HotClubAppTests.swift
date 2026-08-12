//
//  HotClubAppTests.swift
//  HotClubAppTests
//
//  Created by Cindy Michalowski on 10/13/25.
//

import Foundation
import SwiftUI
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

    @Test func catalogRecordRowMatchesSearchAcrossSearchableFields() {
        let record = CatalogRecordRow(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            recordSides: [
                RecordSideRow(
                    id: UUID(),
                    recordId: UUID(),
                    side: .A,
                    songTitle: "In the Mood",
                    artist: "Glenn Miller",
                    personnel: "Tex Beneke; sax",
                    composer: "Joe Garland",
                    label: "Bluebird",
                    year: 1939,
                    keywords: "swing; dance",
                    notes: "Fox trot pressing",
                    imageStoragePath: nil
                ),
                RecordSideRow(
                    id: UUID(),
                    recordId: UUID(),
                    side: .B,
                    songTitle: "A String of Pearls",
                    artist: "Glenn Miller",
                    personnel: nil,
                    composer: "Jerry Gray",
                    label: "Bluebird",
                    year: 1941,
                    keywords: nil,
                    notes: nil,
                    imageStoragePath: nil
                ),
            ]
        )

        #expect(record.matchesSearch(""))
        #expect(record.matchesSearch("   "))
        #expect(record.matchesSearch("mood"))
        #expect(record.matchesSearch("GLENN"))
        #expect(record.matchesSearch("beneke"))
        #expect(record.matchesSearch("bluebird"))
        #expect(record.matchesSearch("garland"))
        #expect(record.matchesSearch("swing"))
        #expect(record.matchesSearch("pearls"))
        #expect(record.matchesSearch("1939"))
        #expect(record.matchesSearch("1941"))
        #expect(record.matchesSearch("fox trot"))
        #expect(!record.matchesSearch("not-a-match"))
    }

    @Test func appThemeIncludesNewPresetsAndCustom() {
        let names = AppTheme.allCases.map(\.rawValue)
        #expect(names.contains("sepia"))
        #expect(names.contains("emerald"))
        #expect(names.contains("champagne"))
        #expect(names.contains("custom"))
        #expect(AppTheme.sepia.builtInPalette.preferredColorScheme == .light)
        #expect(AppTheme.emerald.builtInPalette.preferredColorScheme == .dark)
        #expect(AppTheme.champagne.builtInPalette.preferredColorScheme == .light)
    }

    @Test func customThemeColorsRoundTripsThroughJSON() {
        var custom = CustomThemeColors.default
        custom.accent = RGBAColor(red: 0.1, green: 0.2, blue: 0.3)
        custom.appearance = .dark

        let decoded = CustomThemeColors.decode(from: custom.json)
        #expect(decoded.accent.red == 0.1)
        #expect(decoded.accent.green == 0.2)
        #expect(decoded.accent.blue == 0.3)
        #expect(decoded.appearance == .dark)
    }

    @Test func resolveUsesSelectedSavedCustomTheme() {
        var library = CustomThemeLibrary.default
        library.updateSelected { $0.colors.appearance = .dark }

        let palette = AppTheme.resolve(
            selectionRaw: AppTheme.custom.rawValue,
            customLibraryJSON: library.json
        )
        #expect(palette.preferredColorScheme == .dark)

        let shellac = AppTheme.resolve(
            selectionRaw: AppTheme.shellac.rawValue,
            customLibraryJSON: library.json
        )
        #expect(shellac.preferredColorScheme == .light)
    }

    @Test func customThemeLibrarySupportsCreateDuplicateAndDelete() {
        var library = CustomThemeLibrary.default
        #expect(library.themes.count == 1)

        library.addTheme(named: "Night Desk")
        #expect(library.themes.count == 2)
        #expect(library.selectedTheme.name == "Night Desk")

        library.duplicateSelected()
        #expect(library.themes.count == 3)
        #expect(library.selectedTheme.name == "Night Desk Copy")

        let deletedCopy = library.deleteSelected()
        #expect(deletedCopy)
        #expect(library.themes.count == 2)

        library.selectedThemeID = library.themes[0].id
        let deletedFirst = library.deleteSelected()
        #expect(deletedFirst)
        #expect(library.themes.count == 1)
        let deletedLast = library.deleteSelected()
        #expect(!deletedLast)
    }

    @Test func customThemeLibraryMigratesLegacySingleCustomJSON() {
        var legacy = CustomThemeColors.default
        legacy.appearance = .dark
        legacy.accent = RGBAColor(red: 0.2, green: 0.3, blue: 0.4)

        let migrated = CustomThemeLibrary.decode(from: "", legacyCustomJSON: legacy.json)
        #expect(migrated.themes.count == 1)
        #expect(migrated.selectedTheme.colors.appearance == .dark)
        #expect(migrated.selectedTheme.colors.accent.red == 0.2)
    }

    @Test func decodeInvalidCustomThemeJSONFallsBackToDefault() {
        let decoded = CustomThemeColors.decode(from: "not-json")
        #expect(decoded == CustomThemeColors.default)

        let library = CustomThemeLibrary.decode(from: "not-json")
        #expect(library == CustomThemeLibrary.default)
    }
}
