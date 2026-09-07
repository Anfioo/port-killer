import SwiftUI
import AppKit
import Defaults

struct DependencyRow: View {
    let name: String
    let dependency: PortForwardDependency
    let currentPath: String?
    let isCustom: Bool
    let customPathKey: Defaults.Key<String?>

    @State private var isInstalling = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status row
            HStack {
                Text(name)
                    .font(.headline)

                Spacer()

                if currentPath != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("已安装")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    if isInstalling {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Button("安装") {
                            install()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    if !dependency.isRequired {
                        Text("（可选）")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            // Path row
            if let path = currentPath {
                HStack(spacing: 8) {
                    Text(path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if isCustom {
                        Text("（自定义）")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    } else {
                        Text("（自动）")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Button("浏览...") {
                        browseForPath()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)

                    if isCustom {
                        Button("重置") {
                            Defaults[customPathKey] = nil
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func install() {
        isInstalling = true
        Task {
            _ = await DependencyChecker.shared.checkAndInstallMissing()
            await MainActor.run { isInstalling = false }
        }
    }

    private func browseForPath() {
        let panel = NSOpenPanel()
        panel.title = "选择 \(name) 可执行文件"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/usr/local/bin")

        if panel.runModal() == .OK, let url = panel.url {
            Defaults[customPathKey] = url.path
        }
    }
}
