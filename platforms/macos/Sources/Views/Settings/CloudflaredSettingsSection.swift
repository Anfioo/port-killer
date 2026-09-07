/// CloudflaredSettingsSection - Cloudflare tunnel preferences
///
/// Displays cloudflared settings including:
/// - Transport protocol selection (HTTP/2 or QUIC)

import SwiftUI
import Defaults

struct CloudflaredSettingsSection: View {
    @Default(.cloudflaredProtocol) private var protocolSelection
    @Default(.customCloudflaredPath) private var customPath
    @State private var pathInput = ""

    private let service = CloudflaredService()

    private var effectivePath: String? {
        if let custom = customPath, !custom.isEmpty, FileManager.default.fileExists(atPath: custom) {
            return custom
        }
        return service.autoDetectedPath
    }

    var body: some View {
        SettingsGroup("Cloudflare 隧道", icon: "cloud.fill") {
            VStack(spacing: 0) {
                SettingsRowContainer {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("隧道协议")
                                .fontWeight(.medium)
                            Text("选择 cloudflared 连接 Cloudflare 的方式（仅应用于新隧道）")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Picker("", selection: $protocolSelection) {
                            ForEach(CloudflaredProtocol.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                }

                SettingsDivider()

                SettingsRowContainer {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("cloudflared 路径")
                                .fontWeight(.medium)

                            Spacer()

                            if effectivePath != nil {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("已安装")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                    Text("未找到")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            TextField("自定义路径（留空自动检测）", text: $pathInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                                .onAppear {
                                    pathInput = customPath ?? ""
                                }
                                .onChange(of: pathInput) { _, newValue in
                                    if newValue.isEmpty {
                                        Defaults[.customCloudflaredPath] = nil
                                    } else {
                                        Defaults[.customCloudflaredPath] = newValue
                                    }
                                }

                            if !pathInput.isEmpty {
                                Button("清除") {
                                    pathInput = ""
                                    Defaults[.customCloudflaredPath] = nil
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        if let path = effectivePath {
                            HStack(spacing: 4) {
                                Text("使用中：")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Text(path)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                Text(service.isUsingCustomPath ? "（自定义）" : "（自动）")
                                    .font(.caption2)
                                    .foregroundStyle(service.isUsingCustomPath ? Color.orange : Color.gray)
                            }
                        }
                    }
                }
            }
        }
    }
}
