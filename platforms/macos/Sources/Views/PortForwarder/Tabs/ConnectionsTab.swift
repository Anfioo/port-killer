import SwiftUI

struct ConnectionsTab: View {
    @Environment(AppState.self) private var appState
    @Binding var discoveryManager: KubernetesDiscoveryManager?
    @State private var selectedConnectionId: UUID?

    private var selectedConnection: PortForwardConnectionState? {
        guard let id = selectedConnectionId else { return nil }
        return appState.portForwardManager.connections.first { $0.id == id }
    }

    var body: some View {
        HSplitView {
            // Left: Connection list
            VStack(spacing: 0) {
                // Header with action buttons
                HStack {
                    Text("连接")
                        .font(.headline)

                    Spacer()

                    Button {
                        let config = PortForwardConnectionConfig(
                            name: "新建连接",
                            namespace: "default",
                            service: "service-name",
                            localPort: 8080,
                            remotePort: 80
                        )
                        appState.portForwardManager.addConnection(config)
                    } label: {
                        Label("添加", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .help("添加连接")

                    Button {
                        let dm = KubernetesDiscoveryManager(processManager: appState.portForwardManager.processManager)
                        Task { await dm.loadNamespaces() }
                        discoveryManager = dm
                    } label: {
                        Label("导入", systemImage: "square.and.arrow.down.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!DependencyChecker.shared.allRequiredInstalled)
                    .help("从 Kubernetes 导入")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                Divider()

                // Dependency warning
                if !DependencyChecker.shared.allRequiredInstalled {
                    DependencyWarningBanner()
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(appState.portForwardManager.connections) { connection in
                            PortForwardConnectionCard(
                                connection: connection,
                                isSelected: selectedConnectionId == connection.id,
                                onSelect: { selectedConnectionId = connection.id }
                            )
                        }
                    }
                    .padding(16)
                }

                Divider()

                // Status bar
                HStack {
                    let manager = appState.portForwardManager
                    if manager.connections.isEmpty {
                        Text("暂无配置的连接")
                    } else {
                        Text("\(manager.connectedCount) / \(manager.connections.count) 已连接")
                    }

                    Spacer()

                    if manager.isKillingProcesses {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("正在终止进程...")
                            .foregroundStyle(.secondary)
                    } else if !manager.connections.isEmpty {
                        Button("终止全部卡住进程") {
                            Task { await manager.killStuckProcesses() }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("全部启动") {
                            manager.startAll()
                        }
                        .buttonStyle(.bordered)
                        .disabled(manager.allConnected)

                        Button("全部停止") {
                            manager.stopAll()
                        }
                        .buttonStyle(.bordered)
                        .disabled(manager.connectedCount == 0)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(nsColor: .windowBackgroundColor))
            }
            .frame(minWidth: 400)

            // Right: Log viewer
            ConnectionLogPanel(connection: selectedConnection)
                .frame(minWidth: 450)
        }
    }
}
