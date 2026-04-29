import SwiftUI

struct QWERTYKeyboardView: View {
    let onKeyPress: (String) -> Void
    let onDelete: () -> Void
    let onReturn: () -> Void
    let onNextKeyboard: () -> Void
    let onFixGrammar: () -> Void

    @State private var isCaps = false
    @State private var isFixing = false

    private let rows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]

    var body: some View {
        VStack(spacing: 6) {
            toolbar
            ForEach(0..<rows.count, id: \.self) { i in
                row(index: i)
            }
            bottomRow
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Button {
                guard !isFixing else { return }
                isFixing = true
                onFixGrammar()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isFixing = false }
            } label: {
                HStack(spacing: 4) {
                    if isFixing {
                        ProgressView().scaleEffect(0.7).tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(isFixing ? "Fixing…" : "Fix Grammar")
                        .fontWeight(.medium)
                }
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isFixing)

            Spacer()

            Button(action: onNextKeyboard) {
                Image(systemName: "globe")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Rows

    private func row(index: Int) -> some View {
        HStack(spacing: 5) {
            if index == 2 { capsKey }
            ForEach(rows[index], id: \.self) { letter in
                letterKey(isCaps ? letter.uppercased() : letter)
            }
            if index == 2 { deleteKey }
        }
    }

    private var bottomRow: some View {
        HStack(spacing: 5) {
            charKey("123", width: 44)
            spaceKey
            returnKey
        }
    }

    // MARK: - Keys

    private func letterKey(_ label: String) -> some View {
        Button { onKeyPress(label) } label: {
            Text(label)
                .font(.system(size: 17))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.white)
                .cornerRadius(5)
                .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: 1)
        }
        .foregroundColor(.primary)
    }

    private func charKey(_ label: String, width: CGFloat) -> some View {
        Button { onKeyPress(label) } label: {
            Text(label)
                .font(.system(size: 15))
                .frame(width: width, height: 42)
                .background(Color(.systemGray4))
                .cornerRadius(5)
        }
        .foregroundColor(.primary)
    }

    private var spaceKey: some View {
        Button { onKeyPress(" ") } label: {
            Text("space")
                .font(.system(size: 15))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.white)
                .cornerRadius(5)
                .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: 1)
        }
        .foregroundColor(.primary)
    }

    private var returnKey: some View {
        Button(action: onReturn) {
            Text("return")
                .font(.system(size: 15))
                .frame(width: 88, height: 42)
                .background(Color(.systemGray4))
                .cornerRadius(5)
        }
        .foregroundColor(.primary)
    }

    private var capsKey: some View {
        Button { isCaps.toggle() } label: {
            Image(systemName: isCaps ? "capslock.fill" : "shift")
                .font(.system(size: 16))
                .frame(width: 44, height: 42)
                .background(isCaps ? Color.accentColor.opacity(0.2) : Color(.systemGray4))
                .cornerRadius(5)
        }
        .foregroundColor(isCaps ? .accentColor : .primary)
    }

    private var deleteKey: some View {
        Button(action: onDelete) {
            Image(systemName: "delete.backward")
                .font(.system(size: 16))
                .frame(width: 44, height: 42)
                .background(Color(.systemGray4))
                .cornerRadius(5)
        }
        .foregroundColor(.primary)
    }
}
