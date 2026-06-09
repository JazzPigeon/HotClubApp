import SwiftUI

struct LoginView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.appTheme) private var theme

    @State private var email = ""
    @State private var password = ""
    @State private var mode: Mode = .signIn
    @State private var errorMessage: String?
    @State private var isBusy = false

    private enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Sign in"
        case signUp = "Sign up"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                        .textContentType(mode == .signIn ? .password : .newPassword)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
                Section {
                    Button {
                        Task { await perform() }
                    } label: {
                        if isBusy {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(mode == .signIn ? "Sign in" : "Create account")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isBusy || email.isEmpty || password.count < 6)
                }
                Section {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("78 rmp catalog")
                        .accessibilityIdentifier("App title")
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
        }
    }

    private func perform() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            switch mode {
            case .signIn:
                try await app.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            case .signUp:
                try await app.signUp(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
