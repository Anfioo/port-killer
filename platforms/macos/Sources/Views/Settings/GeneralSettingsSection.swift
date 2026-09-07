/// GeneralSettingsSection - General app preferences
///
/// Displays general settings including:
/// - Launch at login toggle
///
/// - Note: Uses LaunchAtLogin package for login item management.

import SwiftUI
import LaunchAtLogin
import Defaults

struct GeneralSettingsSection: View {
    @Default(.hideSystemProcesses) private var hideSystemProcesses
    @Default(.skipKillConfirmation) private var skipKillConfirmation

    var body: some View {
        SettingsGroup("通用", icon: "gearshape.fill") {
            SettingsRowContainer {
                LaunchAtLogin.Toggle {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("登录时启动")
                            .fontWeight(.medium)
                        Text("登录时自动启动 PortKiller")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }

			SettingsToggleRow(
				title: "隐藏系统进程",
				subtitle: "在进程列表中隐藏 macOS 系统进程",
				isOn: $hideSystemProcesses
			)

            SettingsDivider()

            SettingsToggleRow(
                title: "跳过结束确认",
                subtitle: "无需确认提示，立即结束进程",
                isOn: $skipKillConfirmation
            )
        }
    }
}
