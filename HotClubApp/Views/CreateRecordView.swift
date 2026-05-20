import SwiftUI

struct CreateRecordView: View {
    var onCancel: () -> Void = {}

    @State private var vm = RecordFormViewModel()

    var body: some View {
        NavigationStack {
            RecordFormView(
                vm: vm,
                onCancel: {
                    vm.resetForCreate()
                    onCancel()
                },
                onSaveSuccess: {
                    vm.resetForCreate()
                    onCancel()
                }
            )
            .navigationTitle(vm.navigationTitle)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        vm.resetForCreate()
                        onCancel()
                    }
                    .disabled(vm.isSubmitting)
                }
            }
            .onAppear {
                vm.resetForCreate()
                vm.applyMatchSideAArtist()
                vm.applyMatchSideAComposer()
            }
        }
    }
}
