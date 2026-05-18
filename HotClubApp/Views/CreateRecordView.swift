import PhotosUI
import SwiftUI

struct CreateRecordView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme

    var onCancel: () -> Void = {}

    @State private var vm = CreateRecordViewModel()

    var body: some View {
        @Bindable var vm = vm
        NavigationStack {
            Form {
                if let err = vm.submitError {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                    }
                }
                Section("Side A") {
                    sideAFields
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
                            if ok { onCancel() }
                        }
                    } label: {
                        if vm.isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save record")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(vm.isSubmitting)
                }
            }
            .navigationTitle("New record")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        vm.reset()
                        onCancel()
                    }
                    .disabled(vm.isSubmitting)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .onChange(of: vm.matchSideAArtist) { _, _ in vm.applyMatchSideAArtist() }
            .onChange(of: vm.matchSideAComposer) { _, _ in vm.applyMatchSideAComposer() }
            .onChange(of: vm.sideA.artist) { _, _ in vm.applyMatchSideAArtist() }
            .onChange(of: vm.sideA.composer) { _, _ in vm.applyMatchSideAComposer() }
            .onAppear {
                vm.applyMatchSideAArtist()
                vm.applyMatchSideAComposer()
            }
        }
    }

    @ViewBuilder
    private var sideAFields: some View {
        TextField("Song title", text: $vm.sideA.songTitle)
        TextField("Artist", text: $vm.sideA.artist)
        TextField("Composer", text: $vm.sideA.composer)
        PhotosPicker(selection: $vm.sideA.photoItem, matching: .images, photoLibrary: .shared()) {
            Label("Side image", systemImage: "photo")
        }
    }

    @ViewBuilder
    private var sideBFields: some View {
        TextField("Song title", text: $vm.sideB.songTitle)
        TextField("Artist", text: $vm.sideB.artist)
            .disabled(vm.matchSideAArtist)
        Toggle("Artist - Match Side A", isOn: $vm.matchSideAArtist)
        TextField("Composer", text: $vm.sideB.composer)
            .disabled(vm.matchSideAComposer)
        Toggle("Composer - Match Side A", isOn: $vm.matchSideAComposer)
        PhotosPicker(selection: $vm.sideB.photoItem, matching: .images, photoLibrary: .shared()) {
            Label("Side image", systemImage: "photo")
        }
    }
}
