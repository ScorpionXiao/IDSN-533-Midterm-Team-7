import SwiftUI

/// Keep a text draft so clearing/replacing the value never restores an old age
/// or silently saves it when the current entry is invalid.
struct ProfileAgeField: View {
    @Binding var text: String
    @FocusState private var focused: Bool
    private var invalid: Bool { ProfileAge.parse(text) == nil }

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            HStack(spacing: 6) {
                TextField("Age", text: $text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit { focused = false }
                    .accessibilityLabel("Your age")
                    .accessibilityHint("Enter a whole number from 18 to 100")
                    .accessibilityIdentifier("profile-age-input")
                if focused {
                    Button { focused = false } label: {
                        Image(systemName: "checkmark").font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.vibePink).frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain).accessibilityLabel("Done editing age")
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(invalid ? Color.vibePink.opacity(0.6) : .white.opacity(0.1))
            }
            if invalid {
                Text("Enter 18–100").font(.caption2).foregroundStyle(Color.vibePink)
            }
        }.frame(width: 120)
    }
}
