import SwiftUI

struct AddCustomNamespaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var namespaceInput: String = ""
    @FocusState private var isInputFocused: Bool

    let onAdd: ([String]) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("添加自定义命名空间")
                .font(.headline)

            Text("输入命名空间名称（多个用逗号分隔）")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("例如：production, staging, dev", text: $namespaceInput)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .onSubmit {
                    addNamespaces()
                }

            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("添加") {
                    addNamespaces()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(namespaceInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            isInputFocused = true
        }
    }

    private func addNamespaces() {
        let names = namespaceInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !names.isEmpty else { return }

        onAdd(names)
        dismiss()
    }
}
