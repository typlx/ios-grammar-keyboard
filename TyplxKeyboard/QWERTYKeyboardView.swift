import SwiftUI

struct QWERTYKeyboardView: View {
    let onKeyPress: (String) -> Void
    let onDelete: () -> Void
    let onReturn: () -> Void
    let onNextKeyboard: () -> Void
    let onFixGrammar: () -> Void
    @ObservedObject var viewModel: KeyboardViewModel

    enum Layer { case letters, numbers, symbols }

    @State private var isCaps = false
    @State private var layer: Layer = .letters

    private let letterRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
    ]
    private let numberRows: [[String]] = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
        [".", ",", "?", "!", "'"],
    ]
    private let symbolRows: [[String]] = [
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
        ["_", "\\", "|", "~", "<", ">", "\u{20AC}", "\u{00A3}", "\u{00A5}", "\u{2022}"],
        [".", ",", "?", "!", "'"],
    ]

    var body: some View {
        VStack(spacing: 6) {
            toolbar
            if layer == .letters {
                lettersKeyboard
            } else if layer == .numbers {
                numbersKeyboard
            } else {
                symbolsKeyboard
            }
            bottomRow
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let msg = viewModel.errorMessage {
                Text(msg)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.horizontal, 6)
                    .transition(.opacity)
            }
            HStack {
                Button {
                    guard !viewModel.isFixing else { return }
                    onFixGrammar()
                } label: {
                    HStack(spacing: 4) {
                        if viewModel.isFixing {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(viewModel.isFixing ? "Fixing…" : "Fix Grammar")
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(viewModel.isFixing ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(viewModel.isFixing)

                Spacer()

                Button(action: onNextKeyboard) {
                    Image(systemName: "globe")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Keyboard layers

    @ViewBuilder
    private var lettersKeyboard: some View {
        ForEach(0..<letterRows.count, id: \.self) { letterRow($0) }
    }

    @ViewBuilder
    private var numbersKeyboard: some View {
        ForEach(0..<numberRows.count, id: \.self) { numberRow($0) }
    }

    @ViewBuilder
    private var symbolsKeyboard: some View {
        ForEach(0..<symbolRows.count, id: \.self) { symbolRow($0) }
    }

    // MARK: - Bottom row

    private var bottomRow: some View {
        HStack(spacing: 5) {
            if layer == .letters {
                actionKey("123", width: 44) { layer = .numbers }
            } else {
                actionKey("ABC", width: 44) { layer = .letters }
            }
            spaceKey
            returnKey
        }
    }

    // MARK: - Row builders

    private func letterRow(_ index: Int) -> some View {
        HStack(spacing: 5) {
            if index == 2 { capsKey }
            ForEach(letterRows[index], id: \.self) { letter in
                letterKey(isCaps ? letter.uppercased() : letter)
            }
            if index == 2 { deleteKey }
        }
    }

    private func numberRow(_ index: Int) -> some View {
        HStack(spacing: 5) {
            if index == 2 { actionKey("#+=", width: 44) { layer = .symbols } }
            ForEach(numberRows[index], id: \.self) { key in letterKey(key) }
            if index == 2 { deleteKey }
        }
    }

    private func symbolRow(_ index: Int) -> some View {
        HStack(spacing: 5) {
            if index == 2 { actionKey("123", width: 44) { layer = .numbers } }
            ForEach(symbolRows[index], id: \.self) { key in letterKey(key) }
            if index == 2 { deleteKey }
        }
    }

    // MARK: - Individual keys

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

    private func actionKey(_ label: String, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15))
                .frame(width: width, height: 42)
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
}
