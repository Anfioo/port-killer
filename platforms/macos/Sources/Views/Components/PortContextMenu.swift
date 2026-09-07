/**
 * PortContextMenu.swift
 * PortKiller
 *
 * Shared context menu for port rows across the app.
 * Provides consistent actions for favorites, watching, clipboard, browser, tunnels, and kill.
 */

import SwiftUI
import AppKit

/// Configuration for PortContextMenu to enable/disable specific sections
struct PortContextMenuOptions {
    var includeCopyPortNumber: Bool = true
    var includeCopyCommand: Bool = true
    var includeKillAction: Bool = true
    var includeTunnelActions: Bool = true
    var includeBrowserActions: Bool = true

    static let full = PortContextMenuOptions()
    static let minimal = PortContextMenuOptions(
        includeCopyPortNumber: false,
        includeCopyCommand: false,
        includeKillAction: false,
        includeTunnelActions: false
    )
    static let menuBar = PortContextMenuOptions(
        includeCopyPortNumber: false,
        includeCopyCommand: false,
        includeKillAction: false
    )
    static let nested = PortContextMenuOptions(
        includeCopyPortNumber: false,
        includeCopyCommand: false,
        includeKillAction: false
    )
}

/// Shared context menu component for port actions
struct PortContextMenu: View {
    let port: PortInfo
    let options: PortContextMenuOptions

    @Environment(AppState.self) private var appState

    init(port: PortInfo, options: PortContextMenuOptions = .full) {
        self.port = port
        self.options = options
    }

    var body: some View {
        Group {
            // Favorite & Watch Section
            favoriteWatchSection

            // Copy Section
            if options.includeCopyPortNumber || (options.includeCopyCommand && port.isActive) {
                Divider()
                copySection
            }

            // Process Type Override
            if port.isActive {
                Divider()
                processTypeSection
            }

            // Kill Action
            if options.includeKillAction && port.isActive {
                Divider()
                killSection
            }

            // Browser Section
            if options.includeBrowserActions {
                Divider()
                browserSection
            }

            // Tunnel Section
            if options.includeTunnelActions && port.isActive {
                Divider()
                tunnelSection
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var favoriteWatchSection: some View {
        Button {
            appState.toggleFavorite(port.port)
        } label: {
            Label(
                appState.isFavorite(port.port) ? "取消收藏" : "加入收藏",
                systemImage: appState.isFavorite(port.port) ? "star.slash" : "star"
            )
        }

        Button {
            appState.toggleWatch(port.port)
        } label: {
            Label(
                appState.isWatching(port.port) ? "取消关注" : "关注端口",
                systemImage: appState.isWatching(port.port) ? "eye.slash" : "eye"
            )
        }

        Divider()

        Button {
            promptForPortLabel(port: port.port)
        } label: {
            Label(
                appState.portLabel(for: port.port) != nil ? "编辑标签" : "设置标签",
                systemImage: "pencil"
            )
        }

        if appState.portLabel(for: port.port) != nil {
            Button {
                appState.removePortLabel(for: port.port)
            } label: {
                Label("移除标签", systemImage: "pencil.slash")
            }
        }

        Button {
            promptForPortNote(port: port.port)
        } label: {
            Label(
                appState.portNote(for: port.port) != nil ? "编辑备注" : "添加备注",
                systemImage: "note.text"
            )
        }

        if appState.portNote(for: port.port) != nil {
            Button {
                appState.removePortNote(for: port.port)
            } label: {
                Label("删除备注", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var processTypeSection: some View {
        Menu {
            ForEach(ProcessType.allCases) { type in
                Button {
                    appState.setProcessTypeOverride(processName: port.processName, type: type)
                } label: {
                    HStack {
                        Label(type.rawValue, systemImage: type.icon)
                        if port.processType == type {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            if appState.processTypeOverride(for: port.processName) != nil {
                Divider()
                Button {
                    appState.clearProcessTypeOverride(processName: port.processName)
                } label: {
                    Label("重置为自动", systemImage: "arrow.counterclockwise")
                }
            }
        } label: {
            Label("设置进程类型", systemImage: "tag")
        }
    }

    @ViewBuilder
    private var copySection: some View {
        if options.includeCopyPortNumber {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(String(port.port), forType: .string)
            } label: {
                Label("复制端口号", systemImage: "doc.on.doc")
            }
        }

        if options.includeCopyCommand && port.isActive {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(port.command, forType: .string)
            } label: {
                Label("复制命令", systemImage: "doc.on.doc")
            }
        }
    }

    @ViewBuilder
    private var killSection: some View {
        Button(role: .destructive) {
            Task {
                await appState.killPort(port)
            }
        } label: {
            Label("结束进程", systemImage: "xmark.circle")
        }
        .keyboardShortcut(.delete, modifiers: [])

        Button(role: .destructive) {
            Task {
                await appState.killPortDeep(port)
            }
        } label: {
            Label("深度结束（含连接）", systemImage: "xmark.circle.fill")
        }
    }

    @ViewBuilder
    private var browserSection: some View {
        Button {
            if let url = URL(string: "http://localhost:\(port.port)") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            Label("在浏览器中打开", systemImage: "globe.fill")
        }
        .keyboardShortcut("o", modifiers: .command)

        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("http://localhost:\(port.port)", forType: .string)
        } label: {
            Label("复制 URL", systemImage: "document.on.clipboard")
        }
    }

    @ViewBuilder
    private var tunnelSection: some View {
        if appState.tunnelManager.isCloudflaredInstalled {
            if let tunnel = appState.tunnelManager.tunnelState(for: port.port) {
                if tunnel.status == .active, let url = tunnel.tunnelURL {
                    Button {
                        ClipboardService.copy(url)
                    } label: {
                        Label("复制隧道 URL", systemImage: "doc.on.doc")
                    }

                    Button {
                        if let tunnelURL = URL(string: url) {
                            NSWorkspace.shared.open(tunnelURL)
                        }
                    } label: {
                        Label("打开隧道 URL", systemImage: "globe")
                    }
                }

                Button {
                    appState.tunnelManager.stopTunnel(for: port.port)
                } label: {
                    Label("停止隧道", systemImage: "icloud.slash")
                }
            } else {
                Button {
                    appState.tunnelManager.startTunnel(for: port.port, portInfoId: port.id)
                } label: {
                    Label("通过隧道分享", systemImage: "cloud.fill")
                }
            }
        } else {
            Button {
                ClipboardService.copy("brew install cloudflared")
            } label: {
                Label("复制：brew install cloudflared", systemImage: "doc.on.doc")
            }
        }
    }

    /// Prompts the user to set a custom label for a port via an NSAlert, then persists it.
    private func promptForPortLabel(port: Int) {
        let alert = NSAlert()
        alert.messageText = "设置端口 \(port) 的标签"
        alert.informativeText = "输入自定义名称以标识此端口。"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        textField.placeholderString = "例如：前端开发服务器"
        textField.stringValue = appState.portLabel(for: port) ?? ""
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField

        if alert.runModal() == .alertFirstButtonReturn {
            appState.setPortLabel(textField.stringValue, for: port)
        }
    }

    /// Prompts the user to set a freeform note for a port via an NSAlert with a
    /// multi-line text view, then persists it.
    private func promptForPortNote(port: Int) {
        let alert = NSAlert()
        alert.messageText = "端口 \(port) 的备注"
        alert.informativeText = "添加关于此端口的自由格式备注。"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        let textView = NSTextView(frame: scrollView.bounds)
        textView.string = appState.portNote(for: port) ?? ""
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.isRichText = false
        textView.autoresizingMask = [.width]
        scrollView.documentView = textView

        alert.accessoryView = scrollView
        alert.window.initialFirstResponder = textView

        if alert.runModal() == .alertFirstButtonReturn {
            appState.setPortNote(textView.string, for: port)
        }
    }
}
