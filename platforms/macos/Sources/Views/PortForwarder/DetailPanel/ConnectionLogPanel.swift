import SwiftUI

struct ConnectionLogPanel: View {
    @Environment(AppState.self) private var appState
    let connection: PortForwardConnectionState?
    @State private var showDetails = true

    var body: some View {
        VStack(spacing: 0) {
            if let conn = connection {
                // Edit Form Section
                ConnectionEditSection(connection: conn, isExpanded: $showDetails)

                Divider()

                // Logs Section
                ConnectionLogsSection(connection: conn)
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "sidebar.right")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("选择一个连接")
                        .foregroundStyle(.secondary)
                    Text("点击连接以查看详情和日志")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}
