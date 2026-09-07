import SwiftUI

struct PortForwarderStatusBar: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            // Connection count
            let manager = appState.portForwardManager
            if manager.connections.isEmpty {
                Text("暂无配置的连接")
            } else {
                Text("\(manager.connectedCount) / \(manager.connections.count) 已连接")
            }

            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
