import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    @State private var showAddFavoritePopover = false
    @State private var showAddWatchPopover = false

    var body: some View {
        @Bindable var state = appState

        List(selection: $state.selectedSidebarItem) {
            Section("分类") {
                sidebarRow(.allPorts, count: appState.ports.count)

                // Favorites row with add button
                favoritesRow

                // Watched row with add button
                watchedRow
            }

            Section("网络") {
                kubernetesPortForwardRow
                cloudflareTunnelsRow
            }

            Section("进程类型") {
                ForEach(ProcessType.allCases) { type in
                    sidebarRow(.processType(type), count: countForType(type))
                }
            }

            Section("筛选") {
                filterControls
            }

            Section {
                Label {
                    Text("赞助者")
                } icon: {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                }
                .tag(SidebarItem.sponsors)

                Label("设置", systemImage: "gear")
                    .tag(SidebarItem.settings)
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Favorites Row

    private var favoritesRow: some View {
        Label {
            HStack {
                Text("收藏")
                Spacer()

                Button {
                    showAddFavoritePopover = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("添加收藏端口")
                .popover(isPresented: $showAddFavoritePopover) {
                    AddPortPopover(mode: .favorite) { port, _, _ in
                        appState.favorites.insert(port)
                    }
                }

                Text("\(favoritesCount)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .frame(minWidth: 20)
            }
        } icon: {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
        }
        .tag(SidebarItem.favorites)
        .contextMenu {
            Button {
                showAddFavoritePopover = true
            } label: {
                Label("添加端口…", systemImage: "plus")
            }
        }
    }

    // MARK: - Watched Row

    private var watchedRow: some View {
        Label {
            HStack {
                Text("关注")
                Spacer()

                Button {
                    showAddWatchPopover = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("添加关注端口")
                .popover(isPresented: $showAddWatchPopover) {
                    AddPortPopover(mode: .watch) { port, onStart, onStop in
                        appState.watchedPorts.append(
                            WatchedPort(port: port, notifyOnStart: onStart, notifyOnStop: onStop)
                        )
                    }
                }

                Text("\(watchedCount)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .frame(minWidth: 20)
            }
        } icon: {
            Image(systemName: "eye.fill")
                .foregroundStyle(.blue)
        }
        .tag(SidebarItem.watched)
        .contextMenu {
            Button {
                showAddWatchPopover = true
            } label: {
                Label("添加端口…", systemImage: "plus")
            }
        }
    }

    // MARK: - Kubernetes Port Forward Row

    private var kubernetesPortForwardRow: some View {
        Label {
            HStack {
                Text("K8s 端口转发")
                Spacer()

                // Status indicator
                StatusDot(color: appState.portForwardManager.allConnected && !appState.portForwardManager.connections.isEmpty ? Theme.Colors.statusSuccess : Theme.Colors.statusIdle)

                Text("\(appState.portForwardManager.connections.count)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .frame(minWidth: 20)
            }
        } icon: {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .foregroundStyle(.blue)
        }
        .tag(SidebarItem.kubernetesPortForward)
    }

    // MARK: - Cloudflare Tunnels Row

    private var cloudflareTunnelsRow: some View {
        Label {
            HStack {
                Text("Cloudflare 隧道")
                Spacer()

                let activeCount = appState.tunnelManager.activeTunnelCount + appState.namedTunnelManager.runningCount
                if activeCount > 0 {
                    StatusDot(color: Theme.Colors.statusSuccess)
                }

                let totalCount = appState.tunnelManager.tunnels.count + appState.namedTunnelManager.tunnels.count
                Text("\(totalCount)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .frame(minWidth: 20)
            }
        } icon: {
            Image(systemName: "cloud.fill")
                .foregroundStyle(.orange)
        }
        .tag(SidebarItem.cloudflareTunnels)
    }

    // MARK: - Standard Row

    private func sidebarRow(_ item: SidebarItem, count: Int) -> some View {
        Label {
            HStack {
                Text(item.title)
                Spacer()
                Text("\(count)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        } icon: {
            Image(systemName: item.icon)
        }
        .tag(item)
    }

    // MARK: - Filter Controls

    @ViewBuilder
    private var filterControls: some View {
        @Bindable var state = appState

        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("端口范围")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("最小", value: $state.filter.minPort, format: .number.grouping(.never))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("-")
                        .foregroundStyle(.secondary)
                    TextField("最大", value: $state.filter.maxPort, format: .number.grouping(.never))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }

            if appState.filter.isActive {
                Button("重置筛选") {
                    appState.filter.reset()
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var favoritesCount: Int {
        appState.favorites.count
    }

    private var watchedCount: Int {
        appState.watchedPorts.count
    }

    private func countForType(_ type: ProcessType) -> Int {
        appState.ports.filter { $0.processType == type }.count
    }
}
