import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var appState
    @Environment(SponsorManager.self) private var sponsorManager
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showKillAllConfirmation = false

    var body: some View {
        @Bindable var state = appState

        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } content: {
            contentView
                .searchable(text: $state.filter.searchText, prompt: "搜索端口或进程...")
                .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: .infinity)
        } detail: {
            detailView
                .navigationSplitViewColumnWidth(min: 400, ideal: 500, max: 600)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            toolbarContent
        }
        .onAppear {
            // Ensure app is properly activated for keyboard input
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .confirmationDialog(
            "结束所有进程",
            isPresented: $showKillAllConfirmation
        ) {
            Button("结束全部（\(appState.filteredPorts.count) 个进程）", role: .destructive) {
                Task {
                    await appState.killAll()
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要结束全部 \(appState.filteredPorts.count) 个进程吗？此操作无法撤销。")
        }
        .onKeyPress(.delete) {
            if let port = appState.selectedPort {
                Task {
                    await appState.killPort(port)
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.deleteForward) {
            if let port = appState.selectedPort {
                Task {
                    await appState.killPort(port)
                }
                return .handled
            }
            return .ignored
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch appState.selectedSidebarItem {
        case .settings:
            SettingsView(state: appState, updateManager: appState.updateManager)
                .id("settings")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: .infinity)
        case .sponsors:
            SponsorsPageView(sponsorManager: sponsorManager)
                .id("sponsors")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: .infinity)
        case .kubernetesPortForward:
            PortForwarderSidebarContent()
                .id("port-forwarder")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: .infinity)
        case .cloudflareTunnels:
            CloudflareTunnelsView()
                .id("cloudflare-tunnels")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: .infinity)
        default:
            VStack(spacing: 0) {
                PortTableView()

                // Status bar
                statusBar
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if appState.selectedSidebarItem == .settings || appState.selectedSidebarItem == .sponsors {
            EmptyView()
        } else if appState.selectedSidebarItem == .kubernetesPortForward {
            ConnectionLogPanel(connection: appState.selectedPortForwardConnection)
        } else if appState.selectedSidebarItem == .cloudflareTunnels {
            if let tunnel = appState.selectedNamedTunnel {
                NamedTunnelDetailView(tunnel: tunnel)
            } else {
                ContentUnavailableView {
                    Label("未选择隧道", systemImage: "cloud")
                } description: {
                    Text("从列表中选择一个隧道以查看详情")
                }
            }
        } else if let selectedPort = appState.selectedPort {
            PortDetailView(port: selectedPort)
        } else {
            ContentUnavailableView {
                Label("未选择端口", systemImage: "network.slash")
            } description: {
                Text("从列表中选择一个端口以查看详情")
            }
        }
    }

    private var statusBar: some View {
        HStack {
            // Port count
            Group {
                if appState.filter.isActive || appState.selectedSidebarItem != .allPorts {
                    Text("\(appState.filteredPorts.count) / \(appState.ports.count) 个端口")
                } else {
                    Text("\(appState.ports.count) 个端口正在监听")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            // Scanning indicator
            if appState.isScanning {
                ProgressView()
                    .controlSize(.small)
                Text("扫描中...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                Task {
                    await appState.refresh()
                }
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(appState.isScanning)
            .help("刷新端口列表（⌘R）")

            Button {
                appState.selectedSidebarItem = .settings
            } label: {
                Label("设置", systemImage: "gear")
            }
            .keyboardShortcut(",", modifiers: .command)
            .help("打开设置（⌘,）")
        }
    }
}
