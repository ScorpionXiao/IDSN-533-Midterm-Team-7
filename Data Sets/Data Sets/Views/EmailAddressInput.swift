import SwiftUI
import UIKit

/// Native text input keeps hardware-keyboard/IME composition under UIKit's
/// control. In particular, no character filter or text replacement runs while
/// the input method has marked text.
@MainActor
final class EmailInputController {
    weak var field: UITextField?

    func insertAtSign() {
        guard let field else { return }
        field.becomeFirstResponder()
        field.unmarkText()
        field.insertText("@")
        field.sendActions(for: .editingChanged)
    }

    func commit() -> String? {
        field?.unmarkText()
        let result = field?.text
        field?.resignFirstResponder()
        return result
    }
}

struct EmailAddressInput: UIViewRepresentable {
    @Binding var text: String
    let controller: EmailInputController
    let editingChanged: (Bool) -> Void
    let submit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.placeholder = "you@example.com"
        field.textColor = .white
        field.tintColor = UIColor(Color.vibePink)
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.keyboardType = .emailAddress
        field.textContentType = .emailAddress
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.smartInsertDeleteType = .no
        field.returnKeyType = .go
        field.clearButtonMode = .whileEditing
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        field.accessibilityIdentifier = "login-email"
        field.accessibilityLabel = "Your email"
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        controller.field = field
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        controller.field = field
        if field.markedTextRange == nil && field.text != text {
            field.text = text
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextField, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 250, height: max(26, uiView.intrinsicContentSize.height))
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmailAddressInput
        init(_ parent: EmailAddressInput) { self.parent = parent }

        @objc func changed(_ field: UITextField) {
            guard field.markedTextRange == nil else { return }
            parent.text = field.text ?? ""
        }
        func textFieldDidBeginEditing(_ textField: UITextField) { parent.editingChanged(true) }
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.text = textField.text ?? ""
            parent.editingChanged(false)
        }
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.text = textField.text ?? ""
            parent.submit()
            return false
        }
    }
}
