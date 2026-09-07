import SwiftUI

struct PortPanel: View {
    let service: KubernetesService?
    let selectedPort: KubernetesService.ServicePort?
    @Binding var proxyEnabled: Bool
    let discoveryManager: KubernetesDiscoveryManager
    let onPortSelect: (KubernetesService.ServicePort) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("端口配置")
                    .font(.headline)
                Spacer()
            }
            .padding(12)

            Divider()

            if let service = service {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Port selection
                        ForEach(service.ports) { port in
                            Button {
                                onPortSelect(port)
                            } label: {
                                HStack {
                                    Image(systemName: selectedPort?.id == port.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedPort?.id == port.id ? .blue : .secondary)
                                    Text(port.displayName)
                                        .font(.system(.body, design: .monospaced))
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        if selectedPort != nil {
                            Divider()

                            Toggle("启用代理 (socat)", isOn: $proxyEnabled)

                            let localPort = discoveryManager.suggestLocalPort(for: selectedPort?.port ?? 0)
                            let proxyPort = discoveryManager.suggestProxyPort(for: localPort)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("本地：\(localPort)")
                                    .font(.caption)
                                if proxyEnabled {
                                    Text("代理：\(proxyPort)")
                                        .font(.caption)
                                }
                                Text("连接到：localhost:\(proxyEnabled ? proxyPort : localPort)")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }

                            Button("添加连接", action: onAdd)
                                .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(12)
                }
            } else {
                VStack {
                    Spacer()
                    Text("选择一个服务")
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
        }
    }
}
