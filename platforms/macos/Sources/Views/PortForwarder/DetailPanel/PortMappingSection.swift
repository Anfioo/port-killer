import SwiftUI

struct PortMappingSection: View {
    @Binding var localPort: String
    @Binding var remotePort: String
    @Binding var proxyPort: String
    let proxyEnabled: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("端口映射", systemImage: "arrow.left.arrow.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            // Port flow visualization - centered
            HStack(alignment: .bottom, spacing: 8) {
                // Proxy port (if enabled)
                if proxyEnabled {
                    VStack(spacing: 4) {
                        Text("代理")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        TextField("端口", text: $proxyPort)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            .multilineTextAlignment(.center)
                    }

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.tertiary)
                        .frame(height: 22)
                }

                // Local port
                VStack(spacing: 4) {
                    Text("本地")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    TextField("端口", text: $localPort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                        .multilineTextAlignment(.center)
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.blue)
                    .frame(height: 22)

                // Kubernetes icon
                Image(systemName: "cloud")
                    .foregroundStyle(.blue)
                    .font(.title3)
                    .frame(height: 22)

                Image(systemName: "arrow.right")
                    .foregroundStyle(.blue)
                    .frame(height: 22)

                // Remote port
                VStack(spacing: 4) {
                    Text("远程")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    TextField("端口", text: $remotePort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                        .multilineTextAlignment(.center)
                }
            }
            .font(.system(.body, design: .monospaced))
            .frame(maxWidth: .infinity)
        }
    }
}
