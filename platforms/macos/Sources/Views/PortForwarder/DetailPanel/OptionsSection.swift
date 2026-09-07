import SwiftUI

struct OptionsSection: View {
    @Binding var proxyEnabled: Bool
    @Binding var useDirectExec: Bool
    @Binding var autoReconnect: Bool
    @Binding var isEnabled: Bool
    @Binding var notifyOnConnect: Bool
    @Binding var notifyOnDisconnect: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("选项", systemImage: "gearshape")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                Toggle(isOn: $proxyEnabled) {
                    Label("代理", systemImage: "network")
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                if proxyEnabled {
                    Toggle(isOn: $useDirectExec) {
                        Label("多连接", systemImage: "arrow.triangle.branch")
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .help("启用多个同时连接")
                }

                Spacer()
            }

            HStack(spacing: 20) {
                Toggle(isOn: $autoReconnect) {
                    Label("自动重连", systemImage: "arrow.clockwise")
                }
                .toggleStyle(.checkbox)

                Toggle(isOn: $isEnabled) {
                    Label("已启用", systemImage: "power")
                }
                .toggleStyle(.checkbox)

                Spacer()
            }
            .font(.callout)

            HStack(spacing: 20) {
                Toggle(isOn: $notifyOnConnect) {
                    Label("连接时通知", systemImage: "bell")
                }
                .toggleStyle(.checkbox)

                Toggle(isOn: $notifyOnDisconnect) {
                    Label("断开时通知", systemImage: "bell.slash")
                }
                .toggleStyle(.checkbox)

                Spacer()
            }
            .font(.callout)
        }
    }
}
