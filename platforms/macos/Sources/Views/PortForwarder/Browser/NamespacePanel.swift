import SwiftUI

struct NamespacePanel: View {
    let namespaces: [KubernetesNamespace]
    let selectedNamespace: KubernetesNamespace?
    let state: KubernetesDiscoveryState
    let onSelect: (KubernetesNamespace) -> Void
    let onRefresh: () -> Void
    let onAddCustom: ([String]) -> Void
    let onRemoveCustom: (KubernetesNamespace) -> Void

    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("命名空间")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .help("添加自定义命名空间")
                Button {
                    onRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .disabled(state == .loading)
                .help("刷新命名空间")
            }
            .padding(12)

            Divider()

            if state == .loading {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("加载中...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else if case .error(let msg) = state {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 8) {
                        Button("重试", action: onRefresh)
                            .buttonStyle(.bordered)
                        Button("添加自定义") {
                            showingAddSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(namespaces) { ns in
                            Button { onSelect(ns) } label: {
                                HStack {
                                    Image(systemName: ns.isCustom ? "pencil.and.list.clipboard" : "folder")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(ns.name)
                                        .font(.system(.body, design: .monospaced))
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedNamespace?.id == ns.id ? Color.accentColor.opacity(0.2) : Color.clear)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if ns.isCustom {
                                    Button("移除", role: .destructive) {
                                        onRemoveCustom(ns)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddCustomNamespaceSheet(onAdd: onAddCustom)
        }
    }
}
