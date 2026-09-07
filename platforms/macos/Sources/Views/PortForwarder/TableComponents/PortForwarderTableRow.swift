import SwiftUI

struct PortForwarderTableRow: View {
    @Environment(AppState.self) private var appState
    let connection: PortForwardConnectionState
    let isSelected: Bool
    let onSelect: () -> Void

    private var statusColor: Color {
        if connection.portForwardStatus == .error || connection.proxyStatus == .error {
            return .red
        } else if connection.isFullyConnected {
            return .green
        } else if connection.portForwardStatus == .connecting || connection.proxyStatus == .connecting {
            return .orange
        }
        return .gray
    }

    private var statusText: String {
        if connection.portForwardStatus == .error || connection.proxyStatus == .error {
            return "错误"
        } else if connection.isFullyConnected {
            return "已连接"
        } else if connection.portForwardStatus == .connecting || connection.proxyStatus == .connecting {
            return "连接中"
        }
        return "已停止"
    }

    private var isConnecting: Bool {
        connection.portForwardStatus == .connecting || connection.proxyStatus == .connecting
    }

    var body: some View {
        HStack(spacing: 0) {
            // Status
            HStack(spacing: 4) {
                StatusDot(color: statusColor)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }
            .frame(width: 80, alignment: .leading)

            // Name
            Text(connection.config.name)
                .font(.body)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Service
            Text(connection.config.service)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Port
            Text(":" + String(connection.effectivePort))
                .font(.system(.caption, design: .monospaced))
                .frame(width: 80, alignment: .leading)

            // Actions
            HStack(spacing: 4) {
                if isConnecting {
                    Button {
                        appState.portForwardManager.stopConnection(connection.id)
                    } label: {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 24, height: 24)
                } else if connection.isFullyConnected {
                    Button {
                        appState.portForwardManager.stopConnection(connection.id)
                    } label: {
                        Image(systemName: "stop.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("停止")
                } else {
                    Button {
                        appState.portForwardManager.startConnection(connection.id)
                    } label: {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                    .help("启动")
                }

                Button {
                    appState.portForwardManager.removeConnection(connection.id)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("删除")
            }
            .frame(width: 80, alignment: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            if connection.isFullyConnected {
                Button {
                    appState.portForwardManager.stopConnection(connection.id)
                } label: {
                    Label("停止", systemImage: "stop.fill")
                }
            } else if isConnecting {
                Button {
                    appState.portForwardManager.stopConnection(connection.id)
                } label: {
                    Label("取消", systemImage: "xmark")
                }
            } else {
                Button {
                    appState.portForwardManager.startConnection(connection.id)
                } label: {
                    Label("启动", systemImage: "play.fill")
                }
            }

            Button {
                appState.portForwardManager.restartConnection(connection.id)
            } label: {
                Label("重启", systemImage: "arrow.clockwise")
            }
            .disabled(!connection.isFullyConnected)

            Divider()

            Button(role: .destructive) {
                appState.portForwardManager.removeConnection(connection.id)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}
