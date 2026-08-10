import SwiftUI

struct RecordFormView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme
    @Bindable var vm: RecordFormViewModel

    var showsPersonnel: Bool = true
    var onCancel: () -> Void = {}
    var onSaveSuccess: () -> Void = {}

    var body: some View {
        Form {
            if let err = vm.submitError {
                Section {
                    Text(err)
                        .foregroundStyle(.red)
                }
            }
            Section("Side A") {
                sideFields(side: $vm.sideA, showsPersonnel: showsPersonnel)
            }
            Section("Side B") {
                sideBFields
            }
            Section("Label & year") {
                TextField("Label", text: $vm.label)
                TextField("Year", text: $vm.yearText)
                    .keyboardType(.numberPad)
            }
            Section("Keyword(s)") {
                TextField("Keywords(s)", text: $vm.keywords)
            }
            Section {
                Button {
                    Task {
                        let ok = await vm.submit(app: app)
                        if ok { onSaveSuccess() }
                    }
                } label: {
                    if vm.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(vm.saveButtonTitle)
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(vm.isSubmitting || !vm.canSubmit)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .onChange(of: vm.matchSideAArtist) { _, _ in vm.applyMatchSideAArtist() }
        .onChange(of: vm.matchSideAPersonnel) { _, _ in vm.applyMatchSideAPersonnel() }
        .onChange(of: vm.matchSideAComposer) { _, _ in vm.applyMatchSideAComposer() }
        .onChange(of: vm.sideA.artist) { _, _ in vm.applyMatchSideAArtist() }
        .onChange(of: vm.sideA.personnel) { _, _ in vm.applyMatchSideAPersonnel() }
        .onChange(of: vm.sideA.composer) { _, _ in vm.applyMatchSideAComposer() }
    }

    @ViewBuilder
    private func sideFields(side: Binding<SideFormState>, showsPersonnel: Bool) -> some View {
        SideImageField(croppedPhotoJPEG: side.croppedPhotoJPEG)
        TextField("Song title (required)", text: side.songTitle)
        TextField("Artist", text: side.artist)
        if showsPersonnel {
            TextField("Personnel", text: side.personnel, axis: .vertical)
                .lineLimit(3 ... 8)
        }
        TextField("Composer", text: side.composer)
        TextField("Notes", text: side.notes, axis: .vertical)
            .lineLimit(3 ... 10)
    }

    @ViewBuilder
    private var sideBFields: some View {
        SideImageField(croppedPhotoJPEG: $vm.sideB.croppedPhotoJPEG)
        TextField("Song title (required)", text: $vm.sideB.songTitle)
        TextField("Artist", text: $vm.sideB.artist)
            .disabled(vm.matchSideAArtist)
        Toggle("Artist - Match Side A", isOn: $vm.matchSideAArtist)
        if showsPersonnel {
            TextField("Personnel", text: $vm.sideB.personnel, axis: .vertical)
                .lineLimit(3 ... 8)
                .disabled(vm.matchSideAPersonnel)
            Toggle("Personnel - Match Side A", isOn: $vm.matchSideAPersonnel)
        }
        TextField("Composer", text: $vm.sideB.composer)
            .disabled(vm.matchSideAComposer)
        Toggle("Composer - Match Side A", isOn: $vm.matchSideAComposer)
        TextField("Notes", text: $vm.sideB.notes, axis: .vertical)
            .lineLimit(3 ... 10)
    }
}
