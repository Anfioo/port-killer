import SwiftUI
import LaunchAtLogin
import KeyboardShortcuts
@preconcurrency import UserNotifications

struct OnboardingSetupStep: View {
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("快速设置")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 4)

            // Launch at Login
            VStack(alignment: .leading, spacing: 8) {
                LaunchAtLogin.Toggle {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("登录时启动")
                            .fontWeight(.medium)
                        Text("登录时自动启动 PortKiller")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Notifications
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("通知")
                            .fontWeight(.medium)
                        Text("关注端口状态变化时收到通知")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if notificationStatus == .authorized {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("已启用")
                                .font(.callout)
                                .foregroundStyle(.green)
                        }
                    } else if notificationStatus == .denied {
                        Button("打开设置") {
                            if let bundleId = Bundle.main.bundleIdentifier {
                                let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleId)")!
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .controlSize(.small)
                    } else {
                        Button("启用") {
                            requestPermission()
                        }
                        .controlSize(.small)
                    }
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Keyboard Shortcut
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("全局快捷键")
                            .fontWeight(.medium)
                        Text("从任何位置打开 PortKiller")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    KeyboardShortcuts.Recorder(for: .toggleMainWindow)
                        .frame(width: 150)
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()
        }
        .padding(32)
        .task {
            await checkNotificationStatus()
        }
    }

    private func requestPermission() {
        Task {
            _ = await NotificationService.shared.requestPermission()
            await checkNotificationStatus()
        }
    }

    private func checkNotificationStatus() async {
        guard Bundle.main.bundlePath.hasSuffix(".app") else { return }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }
}
