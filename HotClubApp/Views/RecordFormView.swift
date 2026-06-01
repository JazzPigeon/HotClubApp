import SwiftUI

struct RecordFormView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme
    @Bindable var vm: RecordFormViewModel

    var showsPersonnel: Bool = false
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
        .onChange(of: vm.matchSideAComposer) { _, _ in vm.applyMatchSideAComposer() }
        .onChange(of: vm.sideA.artist) { _, _ in vm.applyMatchSideAArtist() }
        .onChange(of: vm.sideA.composer) { _, _ in vm.applyMatchSideAComposer() }
    }

    @ViewBuilder
    private func sideFields(side: Binding<SideFormState>, showsPersonnel: Bool) -> some View {
        TextField("Song title (required)", text: side.songTitle)
        if showsPersonnel {
            TextField("Personnel", text: side.personnel, axis: .vertical)
                .lineLimit(3 ... 8)
        }
        TextField("Artist", text: side.artist)
        TextField("Composer", text: side.composer)
        SideImageField(croppedPhotoJPEG: side.croppedPhotoJPEG)
    }

    @ViewBuilder
    private var sideBFields: some View {
        TextField("Song title (required)", text: $vm.sideB.songTitle)
        if showsPersonnel {
            TextField("Personnel", text: $vm.sideB.personnel, axis: .vertical)
                .lineLimit(3 ... 8)
        }
        TextField("Artist", text: $vm.sideB.artist)
            .disabled(vm.matchSideAArtist)
        Toggle("Artist - Match Side A", isOn: $vm.matchSideAArtist)
        TextField("Composer", text: $vm.sideB.composer)
            .disabled(vm.matchSideAComposer)
        Toggle("Composer - Match Side A", isOn: $vm.matchSideAComposer)
        SideImageField(croppedPhotoJPEG: $vm.sideB.croppedPhotoJPEG)
    }
}
