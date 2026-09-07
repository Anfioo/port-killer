import SwiftUI

struct CloudflaredMissingBanner: View {
    @Environment(AppState.self) private var appState
    @State private var isCopied = false
    @State private var isInstalling = false
    @State private var installError: String?

    private let installCommand = "brew install cloudflared"

    /// Check if Homebrew is installed
    private var brewPath: String? {
        let paths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        return paths.first { FileManager.default.fileExists(atPath: $0) }
    }

    private var isBrewInstalled: Bool {
        brewPath != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("需要 cloudflared")
                        .font(.headline)
                    if !isBrewInstalled {
                        Text("需要 Homebrew。请访问 brew.sh 安装。")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text("安装 cloudflared 以通过 Cloudflare 隧道分享端口")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Refresh button to re-check installation
                Button {
                    appState.tunnelManager.recheckInstallation()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("检查是否已安装")

                if isBrewInstalled {
                    // Copy command button
                    Button {
                        ClipboardService.copy(installCommand)
                        isCopied = true
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            isCopied = false
                        }
                    } label: {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .help(isCopied ? "已复制！" : "复制命令")

                    // Install button
                    Button {
                        installCloudflared()
                    } label: {
                        if isInstalling {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                            Text("安装中...")
                        } else {
                            Label("安装", systemImage: "arrow.down.circle")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isInstalling)
                } else {
                    // Open brew.sh button
                    Button {
                        if let url = URL(string: "https://brew.sh") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Label("获取 Homebrew", systemImage: "safari")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(12)

            // Error message
            if let error = installError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                    Button("关闭") {
                        installError = nil
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .background(Theme.Colors.link.opacity(0.1))
        .overlay(
            Rectangle()
                .fill(Theme.Colors.link)
                .frame(height: 2),
            alignment: .top
        )
    }

    private func installCloudflared() {
        guard let brewPath = brewPath else { return }

        isInstalling = true
        installError = nil

        Task {
            let result = await ProcessExecutor.run(brewPath, arguments: ["install", "cloudflared"])
            isInstalling = false
            guard let result else {
                installError = "运行 brew 失败"
                return
            }
            if result.succeeded {
                appState.tunnelManager.recheckInstallation()
            } else {
                let combined = result.standardOutput + result.standardError
                let errorOutput = combined.isEmpty ? "未知错误" : combined
                installError = "安装失败：\(errorOutput.prefix(100))"
            }
        }
    }
}
