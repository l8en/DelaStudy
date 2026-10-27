import SwiftUI

struct OnboardingView: View {
    @Bindable var model: AppModel
    @State private var username = ""
    @State private var password = ""
    @State private var mode: EntryMode = .create
    private enum EntryMode: String, CaseIterable { case create = "Create account", login = "Log in" }
    private var signingIn: Bool { mode == .login }
    private var resettingPassword: Bool { model.identity.recoveryUsername != nil }
    private var valid: Bool {
        signingIn ? !username.isEmpty && !password.isEmpty : LocalIdentity.validUsername(username) && LocalIdentity.validPassword(password)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(resettingPassword ? "Choose a new password." : signingIn ? "Back to your studies." : "Make it yours.").font(LensFont.system(.largeTitle, weight: .bold)).tracking(-1)
                        Text(resettingPassword ? "Your study progress stays with your account." : signingIn ? "Log in to your account." : "Your account first. Your study lens next.").font(LensFont.body)
                    }
                    if !resettingPassword { Picker("Account access", selection: $mode) {
                        ForEach(EntryMode.allCases, id: \.self) { option in Text(option.rawValue).tag(option) }
                    }.pickerStyle(.segmented).disabled(model.identity.busy).accessibilityIdentifier("auth-mode") }
                    VStack(alignment: .leading, spacing: 16) {
                        inputLabel("Username") {
                            TextField("Username", text: $username, prompt: Text("e.g. orbit_student").foregroundStyle(LensTheme.slate))
                                .textContentType(.username).textInputAutocapitalization(.never).autocorrectionDisabled()
                                .submitLabel(.done)
                                .accessibilityIdentifier("onboarding-name")
                                .disabled(resettingPassword)
                        }
                        inputLabel("Password") {
                            ProfilePasswordField(text: $password, placeholder: signingIn ? "Password" : "At least 10 characters",
                                identifier: "profile-password", creating: !signingIn) {
                                    if signingIn { submit() }
                                }.id(mode)
                        }
                        if !signingIn {
                            if !username.isEmpty && !LocalIdentity.validUsername(username) {
                                Text("Use 3 to 24 letters, numbers or underscores.").font(LensFont.caption).foregroundStyle(LensTheme.error)
                            }
                        }
                    }
                    if let error = model.identity.error { Text(error).font(LensFont.subheadline).foregroundStyle(LensTheme.error).accessibilityIdentifier("identity-error") }
                    Button(model.identity.busy ? "Please wait…" : resettingPassword ? "Set new password" : signingIn ? "Log in" : "Create account") { submit() }
                        .buttonStyle(LensPrimaryButtonStyle()).disabled(!valid || model.identity.busy).accessibilityIdentifier("start-learning")
                    Text("Accounts stay on this iPhone. No cloud sync.").font(LensFont.caption).foregroundStyle(LensTheme.slate)
                    if signingIn {
                        Button("Forgot your password?") { Task { await model.identity.recover(username: username) } }
                            .font(LensFont.subheadline).frame(minHeight: 44).disabled(model.identity.busy || username.isEmpty)
                    }
                    if resettingPassword {
                        Button("Cancel") { model.identity.cancelRecovery(); mode = .login }.frame(minHeight: 44)
                    }
                }.padding(.horizontal, 24).padding(.bottom, 30)
            }.scrollDismissesKeyboard(.interactively).background(LensTheme.paper).foregroundStyle(LensTheme.navy)
                .onAppear {
                    mode = model.identity.hasAccounts ? .login : .create
                    username = signingIn ? model.identity.username ?? "" : ""
                }
                .onChange(of: mode) { _, _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    password = ""; username = model.identity.recoveryUsername ?? (signingIn ? model.identity.username ?? "" : "")
                    model.identity.error = nil
                }
                .onChange(of: model.identity.recoveryUsername) { _, value in
                    if let value { mode = .create; username = value; password = "" }
                }
        }
    }
    private func inputLabel<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(LensFont.subheadline.weight(.semibold))
            content().font(LensFont.body).padding(14).background(LensTheme.surface, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(LensTheme.border))
        }
    }
    private func submit() {
        guard valid else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        Task {
            if signingIn {
                await model.logIn(username: username, password: password)
            }
            else {
                await model.createAccount(username: username, password: password, courseID: model.selectedCourse.id)
            }
            password = ""
        }
    }
}

/// Keep one native secure text control alive while SwiftUI validates the form.
/// In particular, never replace/reconfigure secure entry after each keystroke.
private struct ProfilePasswordField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let identifier: String
    let creating: Bool
    let submit: () -> Void
    @ScaledMetric(relativeTo: .body) private var fontSize: CGFloat = 17
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> UITextField {
        let view = UITextField()
        view.isSecureTextEntry = true
        view.keyboardType = .asciiCapable
        view.textContentType = creating ? .newPassword : .password
        view.autocorrectionType = .no; view.autocapitalizationType = .none
        view.returnKeyType = .done
        view.accessibilityIdentifier = identifier; view.accessibilityLabel = identifier == "profile-password" ? "Password" : "Confirm password"
        view.font = UIFont(name: "Manrope-Regular", size: fontSize) ?? .systemFont(ofSize: fontSize)
        view.textColor = UIColor(LensTheme.navy)
        view.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor(LensTheme.slate)])
        view.delegate = context.coordinator
        view.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }
    func updateUIView(_ view: UITextField, context: Context) {
        context.coordinator.parent = self
        if view.font?.pointSize != fontSize { view.font = UIFont(name: "Manrope-Regular", size: fontSize) ?? .systemFont(ofSize: fontSize) }
        if !view.isFirstResponder && view.text != text { view.text = text }
    }
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextField, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 200, height: max(25, (uiView.font?.lineHeight ?? 25)+4))
    }
    @MainActor final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ProfilePasswordField
        init(_ parent: ProfilePasswordField) { self.parent = parent }
        @objc func changed(_ field: UITextField) { parent.text = field.text ?? "" }
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let edit = Range(range, in: parent.text) else { return false }
            let value = parent.text.replacingCharacters(in: edit, with: string)
            guard value.utf8.count <= 256 else { return false }
            parent.text = value; textField.text = value
            if let position = textField.position(from: textField.beginningOfDocument, offset: range.location + string.utf16.count) {
                textField.selectedTextRange = textField.textRange(from: position, to: position)
            }
            return false
        }
        func textFieldShouldReturn(_ textField: UITextField) -> Bool { textField.resignFirstResponder(); parent.submit(); return false }
    }
}
