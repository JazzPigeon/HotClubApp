import SwiftUI

struct RecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    let repository: RecordRepository?
    let imageStore: ImageStore?
    var onRecordChanged: () -> Void = {}

    @State private var record: CatalogRecordRow
    @State private var showingSideB = false
    @State private var flipDegrees: Double = 0
    @State private var imageURLA: URL?
    @State private var imageURLB: URL?
    @State private var showDeleteConfirm = false
    @State private var showEdit = false
    @State private var actionError: String?
    @State private var isDeleting = false
    @State private var refreshToken = UUID()

    init(
        record: CatalogRecordRow,
        repository: RecordRepository?,
        imageStore: ImageStore?,
        onRecordChanged: @escaping () -> Void = {}
    ) {
        self.repository = repository
        self.imageStore = imageStore
        self.onRecordChanged = onRecordChanged
        _record = State(initialValue: record)
    }

    private var sideA: RecordSideRow? { record.side(.A) }
    private var sideB: RecordSideRow? { record.side(.B) }

    private var activeRow: RecordSideRow? { showingSideB ? sideB : sideA }

    var body: some View {
        ScrollView {
            ZStack {
                sidePanel(side: .A, row: sideA, imageURL: imageURLA)
                    .modifier(RecordFlipModifier(degrees: flipDegrees, isBack: false))
                sidePanel(side: .B, row: sideB, imageURL: imageURLB)
                    .modifier(RecordFlipModifier(degrees: flipDegrees, isBack: true))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .id(refreshToken)
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button("Delete", role: .destructive) {
                        showDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(isDeleting)
            }
        }
        .navigationDestination(isPresented: $showEdit) {
            EditRecordView(record: record) {
                await reloadRecord()
                onRecordChanged()
            }
        }
        .alert("Delete record?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await deleteRecord() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the record and its images.")
        }
        .alert("Error", isPresented: Binding(
            get: { actionError != nil },
            set: { if !$0 { actionError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionError ?? "")
        }
        .task(id: record.id) { await reloadRecord() }
        .task(id: refreshToken) { await loadImages() }
    }

    private var navigationTitle: String {
        let title = activeRow?.songTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty ? "Record" : title
    }

    private func flipSides() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            showingSideB.toggle()
            flipDegrees = showingSideB ? 180 : 0
        }
    }

    @ViewBuilder
    private func sidePanel(side: RecordSideCode, row: RecordSideRow?, imageURL: URL?) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            squareImage(url: imageURL)
                .contentShape(Rectangle())
                .onTapGesture { flipSides() }

            Text("Side \(side.rawValue)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.secondaryText)

            metadataSection(row: row)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func squareImage(url: URL?) -> some View {
        ZStack {
            theme.secondaryBackground

            Group {
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFit()
                        default:
                            imagePlaceholder
                        }
                    }
                } else {
                    imagePlaceholder
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(theme.secondaryText.opacity(0.25), lineWidth: 1)
        }
        .overlay(alignment: .bottomTrailing) {
            Label("Flip", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption.weight(.medium))
                .padding(8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(10)
        }
    }

    private var imagePlaceholder: some View {
        Image(systemName: "photo")
            .font(.largeTitle)
            .foregroundStyle(theme.secondaryText)
    }

    @ViewBuilder
    private func metadataSection(row: RecordSideRow?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            detailRow(label: "Song Title", value: row?.songTitle)
            detailRow(label: "Artist", value: row?.artist)
            personnelDetailRow(value: row?.personnel)
            detailRow(label: "Composer", value: row?.composer)
            detailRow(label: "Label", value: sharedLabel)
            detailRow(label: "Year", value: sharedYearText)

            Divider()
                .background(theme.secondaryText.opacity(0.35))
                .padding(.vertical, 4)

            notesDetailRow(value: row?.notes)

            detailRow(label: "Keyword(s)", value: sharedKeywords)
        }
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private func personnelDetailRow(value: String?) -> some View {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        VStack(alignment: .leading, spacing: 4) {
            Text("Personnel")
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
            Text(trimmed.isEmpty ? "—" : formattedPersonnel(trimmed))
                .font(.body)
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func notesDetailRow(value: String?) -> some View {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes")
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
            Text(trimmed.isEmpty ? "—" : trimmed)
                .font(.body)
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func detailRow(label: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
            Text(displayValue(value))
                .font(.body)
                .foregroundStyle(theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func formattedPersonnel(_ text: String) -> String {
        text
            .components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ";\n")
    }

    private func displayValue(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "—" : trimmed
    }

    private var sharedLabel: String {
        firstNonEmpty(sideA?.label, sideB?.label)
    }

    private var sharedYearText: String {
        if let year = sideA?.year ?? sideB?.year {
            return String(year)
        }
        return ""
    }

    private var sharedKeywords: String {
        firstNonEmpty(sideA?.keywords, sideB?.keywords)
    }

    private func firstNonEmpty(_ values: String?...) -> String {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }

    private func loadImages() async {
        imageURLA = nil
        imageURLB = nil
        guard let imageStore else { return }
        if let path = sideA?.imageStoragePath, !path.isEmpty {
            imageURLA = try? await imageStore.signedURL(path: path, expiresIn: 3600)
        }
        if let path = sideB?.imageStoragePath, !path.isEmpty {
            imageURLB = try? await imageStore.signedURL(path: path, expiresIn: 3600)
        }
    }

    @MainActor
    private func reloadRecord() async {
        guard let repository else { return }
        do {
            let updated = try await repository.fetchCatalogRecord(id: record.id)
            record = updated
            showingSideB = false
            flipDegrees = 0
            refreshToken = UUID()
            await loadImages()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func deleteRecord() async {
        guard let repository else {
            actionError = AppModelError.noClient.localizedDescription
            return
        }
        isDeleting = true
        defer { isDeleting = false }

        let paths = [sideA?.imageStoragePath, sideB?.imageStoragePath]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

        do {
            try? await imageStore?.delete(paths: paths)
            try await repository.deleteRecord(id: record.id)
            onRecordChanged()
            dismiss()
        } catch {
            actionError = error.localizedDescription
        }
    }
}

/// 3D Y-axis flip: the back face is pre-rotated 180° so Side B reads correctly when revealed.
private struct RecordFlipModifier: ViewModifier {
    let degrees: Double
    let isBack: Bool

    private var isVisible: Bool {
        isBack ? degrees >= 90 : degrees < 90
    }

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isBack ? degrees + 180 : degrees),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
    }
}
