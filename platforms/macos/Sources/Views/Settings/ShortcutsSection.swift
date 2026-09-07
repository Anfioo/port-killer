/**
 * ShortcutsSection.swift
 * PortKiller
 *
 * Keyboard shortcuts configuration section for settings.
 * Allows users to customize global keyboard shortcuts.
 */

import SwiftUI
import KeyboardShortcuts
import ApplicationServices

/// Keyboard shortcuts configuration section
///
/// Displays configurable keyboard shortcuts with:
/// - Inline recorder for setting shortcuts
/// - Reset to default button
/// - Accessibility permission warning when needed
struct ShortcutsSection: View {
    @State private var hasAccessibility = AXIsProcessTrusted()

    var body: some View {
        SettingsGroup("键盘快捷键", icon: "command.square.fill") {
            VStack(spacing: 0) {
                // Toggle Main Window Shortcut
                SettingsRowContainer {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("切换主窗口")
                                .fontWeight(.medium)
                            Text("显示或隐藏 PortKiller 窗口")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        KeyboardShortcuts.Recorder(for: .toggleMainWindow)
                            .frame(width: 130)

                        Button {
                            KeyboardShortcuts.reset(.toggleMainWindow)
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("恢复默认（⌘⇧P）")
                    }
                }

                // Accessibility Permission Warning
                if !hasAccessibility {
                    SettingsDivider()

                    SettingsRowContainer {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("需要辅助功能权限")
                                    .fontWeight(.medium)
                                Text("全局快捷键需要辅助功能权限")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("授予权限") {
                                promptAccessibility()
                            }
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .onAppear {
            hasAccessibility = AXIsProcessTrusted()
        }
    }

    /// Prompts user to grant accessibility permission
    private func promptAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}

#Preview {
    ShortcutsSection()
        .padding()
        .frame(width: 500)
}
