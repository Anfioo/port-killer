import SwiftUI

struct PortForwarderSettingsTab: View {
    @AppStorage("portForwardAutoStart") private var autoStart = false
    @AppStorage("portForwardShowNotifications") private var showNotifications = true

    var body: some View {
        Form {
            Section("启动") {
                Toggle("应用启动时自动启动连接", isOn: $autoStart)
            }

            Section("通知") {
                Toggle("显示连接通知", isOn: $showNotifications)
            }

            Section("依赖项") {
                DependencyRow(
                    name: "kubectl",
                    dependency: DependencyChecker.shared.kubectl,
                    currentPath: DependencyChecker.shared.kubectlPath,
                    isCustom: DependencyChecker.shared.isUsingCustomKubectl,
                    customPathKey: .customKubectlPath
                )

                DependencyRow(
                    name: "socat",
                    dependency: DependencyChecker.shared.socat,
                    currentPath: DependencyChecker.shared.socatPath,
                    isCustom: DependencyChecker.shared.isUsingCustomSocat,
                    customPathKey: .customSocatPath
                )
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
