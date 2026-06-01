import SwiftUI

struct EditRecordView: View {
    @Environment(\.dismiss) private var dismiss

    let record: CatalogRecordRow
    var onSaved: () async -> Void = {}

    @State private var vm = RecordFormViewModel()

    var body: some View {
        RecordFormView(
            vm: vm,
            showsPersonnel: true,
            onSaveSuccess: {
                Task {
                    await onSaved()
                    dismiss()
                }
            }
        )
        .navigationTitle(vm.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .disabled(vm.isSubmitting)
            }
        }
        .onAppear {
            vm.loadForEdit(record)
        }
    }
}
