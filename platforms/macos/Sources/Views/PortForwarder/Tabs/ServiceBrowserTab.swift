import SwiftUI

struct ServiceBrowserTab: View {
    @Environment(AppState.self) private var appState
    @State private var discoveryManager: KubernetesDiscoveryManager?

    var body: some View {
        VStack {
            if let dm = discoveryManager {
                ServiceBrowserEmbedded(
                    discoveryManager: dm,
                    onServiceSelected: { config in
                        appState.portForwardManager.addConnection(config)
                    }
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)

                    Text("Kubernetes 服务浏览器")
                        .font(.title2)

                    Text("浏览 Kubernetes 集群以查找服务并创建端口转发连接。")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)

                    Button("开始浏览") {
                        let dm = KubernetesDiscoveryManager(processManager: appState.portForwardManager.processManager)
                        Task { await dm.loadNamespaces() }
                        discoveryManager = dm
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!DependencyChecker.shared.allRequiredInstalled)

                    if !DependencyChecker.shared.allRequiredInstalled {
                        Text("需要 kubectl")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ServiceBrowserEmbedded: View {
    @Bindable var discoveryManager: KubernetesDiscoveryManager
    let onServiceSelected: (PortForwardConnectionConfig) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 3 panel layout
            HStack(spacing: 0) {
                // Namespace List
                NamespacePanel(
                    namespaces: discoveryManager.namespaces,
                    selectedNamespace: discoveryManager.selectedNamespace,
                    state: discoveryManager.namespaceState,
                    onSelect: { namespace in
                        Task { await discoveryManager.selectNamespace(namespace) }
                    },
                    onRefresh: {
                        Task { await discoveryManager.loadNamespaces() }
                    },
                    onAddCustom: { namespaceNames in
                        discoveryManager.addCustomNamespaces(namespaceNames)
                    },
                    onRemoveCustom: { namespace in
                        discoveryManager.removeCustomNamespace(namespace)
                    }
                )
                .frame(width: 200)

                Divider()

                // Service List
                ServicePanel(
                    services: discoveryManager.services,
                    selectedService: discoveryManager.selectedService,
                    state: discoveryManager.serviceState,
                    onSelect: { service in
                        discoveryManager.selectService(service)
                    }
                )
                .frame(minWidth: 250)

                Divider()

                // Port Selection
                PortPanel(
                    service: discoveryManager.selectedService,
                    selectedPort: discoveryManager.selectedPort,
                    proxyEnabled: $discoveryManager.proxyEnabled,
                    discoveryManager: discoveryManager,
                    onPortSelect: { port in
                        discoveryManager.selectPort(port)
                    },
                    onAdd: {
                        if let config = discoveryManager.createConnectionConfig() {
                            onServiceSelected(config)
                        }
                    }
                )
                .frame(width: 250)
            }
        }
    }
}
