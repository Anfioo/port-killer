import SwiftUI

/// Right-pane detail view for a selected named Cloudflare tunnel.
/// Shows full ingress mapping, edge connections, metadata, and live logs.
/// Mirrors the structure of `PortDetailView` so the two panes feel consistent.
struct NamedTunnelDetailView: View {
    let tunnel: NamedCloudflareTunnel
    @Environment(AppState.self) private var appState
    @State private var showLogs = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                Divider()

                metaSection

                if !tunnel.ingressRules.isEmpty {
                    Divider()
                    ingressSection
                }

                if !tunnel.edgeConnections.isEmpty {
                    Divider()
                    edgeConnectionsSection
                }

                if tunnel.runSafety == .managedElsewhere {
                    Divider()
                    managedElsewhereExplanation
                }

                Divider()

                logsSection
            }
            .padding()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconBadge(systemName: "cloud.fill", color: statusColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tunnel.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(tunnel.status.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            statusBadges
            actionRow
        }
    }

    private var statusColor: Color {
        switch tunnel.status {
        case .running: .green
        case .starting, .stopping: .yellow
        case .error: .red
        case .stopped:
            tunnel.runSafety == .managedElsewhere ? .orange : .secondary
        }
    }

    private var statusBadges: some View {
        HStack(spacing: 8) {
            badge(text: tunnel.status.rawValue, tint: statusColor)

            if tunnel.status == .running {
                badge(
                    text: "\(tunnel.activeConnectionCount) 个连接",
                    icon: "link",
                    tint: .green
                )
            }

            switch tunnel.runSafety {
            case .safe:
                if tunnel.hasLocalConfigMatch {
                    badge(text: "本地配置", icon: "doc.text", tint: .blue)
                }
            case .managedElsewhere:
                badge(text: "其他位置管理", icon: "lock.fill", tint: .orange)
            case .noIngress:
                badge(text: "无入口规则", icon: "exclamationmark.triangle", tint: .yellow)
            }

            Spacer()
        }
    }

    private func badge(text: String, icon: String? = nil, tint: Color) -> some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon) }
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.2))
        .foregroundStyle(tint)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var actionRow: some View {
        HStack(spacing: 8) {
            switch tunnel.status {
            case .stopped, .error:
                if tunnel.runSafety == .managedElsewhere {
                    Button {
                        appState.namedTunnelManager.run(tunnel, allowManagedElsewhere: true)
                    } label: {
                        Label("仍要运行", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.orange)
                    .disabled(!appState.tunnelManager.isCloudflaredInstalled)
                    .help("将此 Mac 添加为隧道的另一个连接器")
                } else {
                    Button {
                        appState.namedTunnelManager.run(tunnel)
                    } label: {
                        Label("运行隧道", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!appState.tunnelManager.isCloudflaredInstalled)
                }
            case .starting, .stopping:
                Button {} label: {
                    HStack { ProgressView().controlSize(.small); Text(tunnel.status.rawValue) }
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(true)
            case .running:
                Button {
                    appState.namedTunnelManager.stop(tunnel)
                } label: {
                    Label("停止隧道", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.red)
            }
        }
    }

    // MARK: - Meta

    private var metaSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), alignment: .topLeading),
            GridItem(.flexible(), alignment: .topLeading)
        ], spacing: 16) {
            metaItem(label: "隧道 ID", value: tunnel.tunnelID, monospaced: true)
            metaItem(label: "入口来源", value: ingressSourceLabel)
            if let created = tunnel.createdAt {
                metaItem(label: "创建时间", value: created.formatted(date: .abbreviated, time: .shortened))
            }
            if let metricsPort = tunnel.metricsPort {
                metaItem(label: "指标", value: "127.0.0.1:\(metricsPort)", monospaced: true)
            }
            if let started = tunnel.startedAt, tunnel.status == .running {
                metaItem(label: "启动时间", value: started.formatted(.relative(presentation: .named)))
            }
            if let credentials = tunnel.credentialsPath {
                metaItem(label: "凭证", value: (credentials as NSString).abbreviatingWithTildeInPath, monospaced: true)
            }
        }
    }

    private var ingressSourceLabel: String {
        switch tunnel.ingressSource {
        case .none: return "—"
        case .localConfig: return "~/.cloudflared/config.yml"
        case .runtimeLog: return "Cloudflare 仪表盘"
        }
    }

    private func metaItem(label: String, value: String, monospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(monospaced ? .system(.caption, design: .monospaced) : .callout)
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)
        }
    }

    // MARK: - Ingress

    private var ingressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("入口规则")
                .font(.headline)

            VStack(spacing: 4) {
                ForEach(Array(tunnel.ingressRules.enumerated()), id: \.offset) { _, rule in
                    IngressRuleDetailRow(rule: rule)
                }
            }
        }
    }

    // MARK: - Edge Connections

    private var edgeConnectionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("边缘连接")
                    .font(.headline)
                Text("\(tunnel.edgeConnections.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
                Spacer()
            }

            VStack(spacing: 4) {
                ForEach(tunnel.edgeConnections, id: \.id) { conn in
                    HStack(spacing: 10) {
                        StatusDot(
                            color: conn.isPendingReconnect ? Theme.Colors.statusWarning : Theme.Colors.statusSuccess,
                            size: Sizing.statusDotSmall
                        )
                        Text(conn.coloName)
                            .font(.system(.callout, design: .monospaced).weight(.semibold))
                            .frame(minWidth: 60, alignment: .leading)
                        Text(conn.originIP)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let opened = conn.openedAt {
                            Text(opened, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    // MARK: - Managed Elsewhere Explanation

    private var managedElsewhereExplanation: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("此隧道由其他源管理")
                    .font(.subheadline.weight(.semibold))
                Text("它有来自其他机器的活动边缘连接，且没有本地入口配置。在此处运行会将此 Mac 添加为另一个连接器，可能在多个源之间分流流量。仅在确有意向时使用「仍要运行」。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.08)))
    }

    // MARK: - Logs

    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("日志")
                    .font(.headline)
                Spacer()
                if !tunnel.logs.isEmpty {
                    Text("\(tunnel.logs.count) 条")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Button {
                        tunnel.clearLogs()
                    } label: {
                        Label("清除", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                Button {
                    showLogs.toggle()
                } label: {
                    Image(systemName: showLogs ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if showLogs {
                if tunnel.logs.isEmpty {
                    Text(tunnel.status == .running ? "等待输出…" : "暂无日志。运行隧道以查看实时输出。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    NamedTunnelLogView(tunnel: tunnel)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
