import SwiftUI

struct PortForwarderToolbar: View {
    @Environment(AppState.self) private var appState
    @Binding var searchText: String
    @Binding var groupByNamespace: Bool
    @Binding var discoveryManager: KubernetesDiscoveryManager?

    var body: some View {
        HStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)
            .frame(maxWidth: 200)

            // Group toggle
            Button {
                groupByNamespace.toggle()
            } label: {
                Image(systemName: groupByNamespace ? "folder.fill" : "list.bullet")
            }
            .buttonStyle(.bordered)
            .help(groupByNamespace ? "显示扁平列表" : "按命名空间分组")

            Spacer()

            let manager = appState.portForwardManager

            if !manager.connections.isEmpty {
                Button {
                    manager.startAll()
                } label: {
                    Label("全部启动", systemImage: "play.fill")
                }
                .buttonStyle(.bordered)
                .disabled(manager.allConnected)

                Button {
                    manager.stopAll()
                } label: {
                    Label("全部停止", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                .disabled(manager.connectedCount == 0)

                Button {
                    Task { await manager.killStuckProcesses() }
                } label: {
                    Label("强制停止", systemImage: "xmark.octagon.fill")
                }
                .buttonStyle(.bordered)
                .help("终止所有卡住的 kubectl/socat 进程")
            }

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

            Button {
                let dm = KubernetesDiscoveryManager(processManager: appState.portForwardManager.processManager)
                Task { await dm.loadNamespaces() }
                discoveryManager = dm
            } label: {
                Label("导入", systemImage: "square.and.arrow.down.fill")
            }
            .buttonStyle(.bordered)
            .disabled(!DependencyChecker.shared.allRequiredInstalled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
