import PhotosUI
import PhotosUI
import SwiftUI

struct CreateRecordView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme

    @State private var vm = CreateRecordViewModel()
    @State private var showSaved = false

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
                    sideFields(side: $vm.sideA)
                }
                Section("Side B") {
                    sideFields(side: $vm.sideB)
                }
                Section {
                    Button {
                        Task {
                            let ok = await vm.submit(app: app)
                            if ok { showSaved = true }
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
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .alert("Saved", isPresented: $showSaved) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your record was added to Supabase.")
            }
        }
    }

    @ViewBuilder
    private func sideFields(side: Binding<SideFormState>) -> some View {
        TextField("Song title", text: side.songTitle)
        TextField("Artist", text: side.artist)
        TextField("Composer", text: side.composer)
        TextField("Label", text: side.label)
        TextField("Year", text: side.yearText)
            .keyboardType(.numberPad)
        PhotosPicker(selection: side.photoItem, matching: .images, photoLibrary: .shared()) {
            Label("Side image", systemImage: "photo")
        }
    }
}
