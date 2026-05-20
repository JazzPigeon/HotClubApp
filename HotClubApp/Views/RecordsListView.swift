import Supabase
import SwiftUI

struct RecordsListView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme

    @State private var records: [CatalogRecordRow] = []
    @State private var loadError: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading, records.isEmpty {
                    ProgressView("Loading records…")
                } else if let loadError {
                    ContentUnavailableView {
                        Label("Could not load", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(loadError)
                    }
                } else if records.isEmpty {
                    ContentUnavailableView {
                        Label("No records yet", systemImage: "opticaldisc")
                    } description: {
                        Text("Add a record from the Add tab.")
                    }
                } else {
                    List(records) { record in
                        NavigationLink(value: record) {
                            RecordSummaryRow(record: record, client: app.client)
                        }
                        .listRowBackground(theme.secondaryBackground)
                    }
                }
            }
            .navigationDestination(for: CatalogRecordRow.self) { record in
                RecordDetailView(record: record, client: app.client) {
                    Task { await load() }
                }
            }
            .navigationTitle("Records")
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .onAppear { Task { await load() } }
            .refreshable { await load() }
        }
    }

    private func load() async {
        guard let client = app.client else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            records = try await RecordService(client: client).fetchCatalogRecords()
        } catch {
            loadError = error.localizedDescription
        }
    }
}

struct RecordSummaryRow: View {
    let record: CatalogRecordRow
    let client: SupabaseClient?
    @Environment(\.appTheme) private var theme

    @State private var thumbURL: URL?

    private var sideA: RecordSideRow? { record.side(.A) }
    private var sideB: RecordSideRow? { record.side(.B) }

    private var titleText: String {
        let a = sideA?.songTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let b = sideB?.songTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !a.isEmpty, !b.isEmpty { return "\(a) | \(b)" }
        if !a.isEmpty { return a }
        if !b.isEmpty { return b }
        return "Untitled"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumb
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .task(id: record.id) { await resolveThumb() }
    }

    private var subtitle: String {
        let parts = [sideA?.label, sideA?.year.map(String.init)].compactMap { $0 }
        let s = parts.joined(separator: " · ")
        return s.isEmpty ? "Side A" : s
    }

    @ViewBuilder
    private var thumb: some View {
        Group {
            if let thumbURL {
                AsyncImage(url: thumbURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: "photo")
                            .foregroundStyle(theme.secondaryText)
                    }
                }
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .frame(width: 52, height: 52)
        .background(theme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func resolveThumb() async {
        thumbURL = nil
        guard let path = sideA?.imageStoragePath, !path.isEmpty, let client else { return }
        do {
            thumbURL = try await StorageService(client: client).signedURL(path: path, expiresIn: 3600)
        } catch {
            thumbURL = nil
        }
    }
}
