import SwiftUI

struct PortDetailView: View {
    let port: PortInfo
    @Environment(AppState.self) private var appState
    @State private var showKillConfirmation = false
    @State private var noteDraft = ""
    @FocusState private var noteFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                header

                Divider()

                // Details Grid
                detailsGrid

                Divider()

                // Notes
                notesSection

                // Tunnel exposures (only shown when ≥1 named tunnel maps to this port)
                if !exposures.isEmpty {
                    Divider()
                    exposuresSection
                }

                Divider()

                // Command
                commandSection

                Divider()

                // Actions
                actionsSection
            }
            .padding()
        }
        .confirmationDialog(
            "结束进程",
            isPresented: $showKillConfirmation
        ) {
            Button("结束进程", role: .destructive) {
                Task {
                    await appState.killPort(port)
                }
            }
            Button("强制结束（SIGKILL）", role: .destructive) {
                Task {
                    await appState.killPort(port)
                }
            }
            Button("深度结束（含连接）", role: .destructive) {
                Task {
                    await appState.killPortDeep(port)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要结束端口 \(String(port.port)) 上的 \(port.processName) 吗？")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconBadge(systemName: port.processType.icon, color: port.processType.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(port.processName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text("端口 \(String(port.port))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let label = appState.portLabel(for: port.port) {
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text(label)
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Text(port.processType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(port.processType.color.opacity(0.2))
                    .foregroundStyle(port.processType.color)
                    .clipShape(Capsule())

                if appState.isFavorite(port.port) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                        Text("已收藏")
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.yellow.opacity(0.2))
                    .foregroundStyle(.yellow)
                    .clipShape(Capsule())
                }

                if appState.isWatching(port.port) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                        Text("关注中")
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.2))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                }

                Spacer()
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("备注")
                    .font(.headline)
                Spacer()
                if appState.portNote(for: port.port) != nil {
                    Button("清除") {
                        appState.removePortNote(for: port.port)
                        noteDraft = ""
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            }

            TextEditor(text: $noteDraft)
                .focused($noteFocused)
                .font(.body)
                .frame(minHeight: 64, maxHeight: 140)
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .topLeading) {
                    if noteDraft.isEmpty {
                        Text("为端口 \(String(port.port)) 添加备注…")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
                .onChange(of: noteFocused) { _, focused in
                    // Persist when focus leaves the editor.
                    if !focused { appState.setPortNote(noteDraft, for: port.port) }
                }
        }
        .onAppear { noteDraft = appState.portNote(for: port.port) ?? "" }
        .onChange(of: port.port) { _, _ in
            noteDraft = appState.portNote(for: port.port) ?? ""
        }
    }

    private var detailsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], alignment: .leading, spacing: 16) {
            DetailRow(title: "端口", value: String(port.port))
            DetailRow(title: "标签", value: appState.portLabel(for: port.port) ?? "—")
            DetailRow(title: "PID", value: String(port.pid))
            DetailRow(title: "地址", value: port.address)
            DetailRow(title: "用户", value: port.user)
            DetailRow(title: "文件描述符", value: port.fd)
            DetailRow(title: "类型", value: port.processType.rawValue)
        }
    }

    private var exposures: [PortExposure] {
        guard port.isActive else { return [] }
        return appState.namedTunnelManager.exposures(for: port.port)
    }

    private var exposuresSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "globe").foregroundStyle(.orange)
                Text("通过 Cloudflare 隧道暴露")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(exposures, id: \.publicURL) { exposure in
                    HStack(spacing: 8) {
                        Button {
                            if let url = URL(string: exposure.publicURL) {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(exposure.publicURL)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.blue)
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text(exposure.tunnelName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            ClipboardService.copy(exposure.publicURL)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("复制 URL")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    private var commandSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("命令")
                    .font(.headline)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(port.command, forType: .string)
                } label: {
                    Label("复制", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text(port.command.count > AppConstants.maxCommandLength
                ? String(port.command.prefix(AppConstants.maxCommandLength)) + "..."
                : port.command)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("操作")
                .font(.headline)

            VStack(spacing: 8) {
                FavoriteWatchButtons(portNumber: port.port, style: .labeled)

                // Tunnel section
                if port.isActive {
                    tunnelSection
                }

                Button(role: .destructive) {
                    showKillConfirmation = true
                } label: {
                    Text("结束进程")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
    }

    @ViewBuilder
    private var tunnelSection: some View {
        if !appState.tunnelManager.isCloudflaredInstalled {
            CloudflaredMissingBanner()
        } else if let tunnel = appState.tunnelManager.tunnelState(for: port.port) {
            TunnelStatusBadge(
                tunnel: tunnel,
                onCopyURL: {
                    appState.tunnelManager.copyURL(for: port.port)
                },
                onStop: {
                    appState.tunnelManager.stopTunnel(for: port.port)
                }
            )
        } else {
            Button {
                appState.tunnelManager.startTunnel(for: port.port, portInfoId: port.id)
            } label: {
                HStack {
                    Image(systemName: "cloud.fill")
                    Text("通过隧道分享")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .help("通过 Cloudflare 隧道为此端口创建公开 URL")
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}
