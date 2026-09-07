/// SettingsView - Main settings interface
///
/// Displays app settings organized into sections:
/// - General preferences (launch at login)
/// - Keyboard shortcuts (global hotkeys)
/// - Permissions (accessibility, notifications)
/// - Software updates (Sparkle integration)
/// - Sponsors configuration
/// - About information
///
/// - Note: Automatically checks permissions every 5 seconds while visible.
/// - Important: Uses `@Bindable var state: AppState` for state management.

import SwiftUI
import ApplicationServices
@preconcurrency import UserNotifications
import Sparkle
import LaunchAtLogin
import Defaults

struct SettingsView: View {
    @Bindable var state: AppState
    var updateManager: UpdateManager
    @Environment(SponsorManager.self) var sponsorManager
    @Environment(\.openWindow) private var openWindow
    @State private var hasAccessibility = AXIsProcessTrusted()
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var sponsorDisplayInterval = Defaults[.sponsorDisplayInterval]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // MARK: - General
                GeneralSettingsSection()

                // MARK: - Port Forwarding
                PortForwardingSettingsSection()

                // MARK: - Auto-Kill Rules
                AutoKillSettingsSection()

                // MARK: - Notifications
                NotificationsSettingsSection()

                // MARK: - Cloudflare Tunnels
                CloudflaredSettingsSection()

                // MARK: - Keyboard Shortcuts
                ShortcutsSection()

                // MARK: - Permissions
                PermissionsSection(
                    hasAccessibility: $hasAccessibility,
                    notificationStatus: $notificationStatus,
                    onRequestNotification: requestNotificationPermission,
                    onOpenNotificationSettings: openNotificationSettings
                )

                // MARK: - Updates
                SettingsGroup("软件更新", icon: "arrow.triangle.2.circlepath") {
                    VStack(spacing: 0) {
                        SettingsRowContainer {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("PortKiller \(AppInfo.versionString)")
                                        .fontWeight(.medium)
                                    if let lastCheck = updateManager.lastUpdateCheckDate {
                                        Text("上次检查：\(lastCheck.formatted(.relative(presentation: .named)))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("从未检查更新")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Button("立即检查") {
                                    updateManager.checkForUpdates()
                                }
                                .disabled(!updateManager.canCheckForUpdates)
                            }
                        }

                        SettingsDivider()

                        SettingsToggleRow(
                            title: "自动检查",
                            subtitle: "在后台查找更新",
                            isOn: Binding(
                                get: { updateManager.automaticallyChecksForUpdates },
                                set: { updateManager.automaticallyChecksForUpdates = $0 }
                            )
                        )

                        SettingsDivider()

                        SettingsToggleRow(
                            title: "自动下载",
                            subtitle: "有更新时自动下载",
                            isOn: Binding(
                                get: { updateManager.automaticallyDownloadsUpdates },
                                set: { updateManager.automaticallyDownloadsUpdates = $0 }
                            )
                        )
                    }
                }

                // MARK: - Sponsors
                SettingsGroup("赞助者", icon: "heart.fill") {
                    VStack(spacing: 0) {
                        SettingsRowContainer {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("显示赞助者窗口")
                                        .fontWeight(.medium)
                                    Text("显示赞助者窗口的频率")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Picker("", selection: $sponsorDisplayInterval) {
                                    ForEach(SponsorDisplayInterval.allCases, id: \.self) { interval in
                                        Text(interval.localizedName).tag(interval)
                                    }
                                }
                                .frame(width: 130)
                                .onChange(of: sponsorDisplayInterval) { _, newValue in
                                    Defaults[.sponsorDisplayInterval] = newValue
                                }
                            }
                        }

                        SettingsDivider()

                        SettingsRowContainer {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("查看赞助者")
                                        .fontWeight(.medium)
                                    Text("查看所有当前支持者")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button("显示窗口") {
                                    sponsorManager.showSponsorsWindow()
                                    openWindow(id: "sponsors")
                                }
                            }
                        }
                    }
                }

                // MARK: - About
                SettingsGroup("关于", icon: "info.circle.fill") {
                    VStack(spacing: 0) {
                        SettingsRowContainer {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("开发者")
                                        .fontWeight(.medium)
                                    Text("productdevbook")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }

                        SettingsDivider()

                        SettingsLinkRow(title: "GitHub", subtitle: "为项目点星", icon: "star.fill", url: AppInfo.githubRepo)
                        SettingsDivider()
                        SettingsLinkRow(title: "赞助", subtitle: "支持开发", icon: "heart.fill", url: AppInfo.githubSponsors)
                        SettingsDivider()
                        SettingsLinkRow(title: "报告问题", subtitle: "发现 Bug？", icon: "ladybug.fill", url: AppInfo.githubIssues)
                        SettingsDivider()
                        SettingsLinkRow(title: "Twitter/X", subtitle: "@productdevbook", icon: "at", url: AppInfo.twitterURL)
                        SettingsDivider()
                        SettingsButtonRow(
                            title: "显示欢迎界面",
                            subtitle: "重新播放引导向导",
                            icon: "hand.wave.fill",
                            action: {
                                Defaults[.hasCompletedOnboarding] = false
                            }
                        )
                    }
                }
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            // Periodically check permissions while view is visible
            // Task automatically cancels when view disappears
            while !Task.isCancelled {
                checkPermissions()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    // MARK: - Permission Management

    /// Checks current permission states
    private func checkPermissions() {
        // Check accessibility
        hasAccessibility = AXIsProcessTrusted()

        // Check notification permission (only works in .app bundle)
        guard Bundle.main.bundleIdentifier != nil,
              Bundle.main.bundlePath.hasSuffix(".app") else {
            // Running from debug build, skip notification check
            notificationStatus = .notDetermined
            return
        }

        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                notificationStatus = settings.authorizationStatus
            }
        }
    }

    /// Requests notification permission from user
    private func requestNotificationPermission() {
        guard Bundle.main.bundlePath.hasSuffix(".app") else { return }

        Task {
            do {
                _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    checkPermissions()
                }
            } catch {
                // Permission denied or error
            }
        }
    }

    /// Opens system notification settings for this app
    private func openNotificationSettings() {
        // Open System Settings > Notifications for this app
        if let bundleId = Bundle.main.bundleIdentifier {
            let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleId)")!
            NSWorkspace.shared.open(url)
        }
    }
}
