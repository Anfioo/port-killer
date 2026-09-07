import SwiftUI
import Defaults

struct AutoKillSettingsSection: View {
    @Default(.autoKillRules) private var rules
    @State private var editingRule: AutoKillRule?
    @State private var isAddingRule = false

    var body: some View {
        SettingsGroup("自动结束规则", icon: "clock.badge.xmark") {
            VStack(spacing: 0) {
                SettingsRowContainer {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("超时后自动结束进程")
                            .fontWeight(.medium)
                        Text("每个端口扫描周期都会检查规则")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                SettingsDivider()

                if rules.isEmpty {
                    SettingsRowContainer {
                        HStack {
                            Text("未配置规则")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("添加规则") {
                                isAddingRule = true
                            }
                            .controlSize(.small)
                        }
                    }
                } else {
                    ForEach(rules) { rule in
                        ruleRow(rule)
                        if rule.id != rules.last?.id {
                            SettingsDivider()
                        }
                    }

                    SettingsDivider()

                    SettingsRowContainer {
                        HStack {
                            Spacer()
                            Button("添加规则") {
                                isAddingRule = true
                            }
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isAddingRule) {
            AutoKillRuleEditor(rule: AutoKillRule(name: "新规则")) { newRule in
                rules.append(newRule)
            }
        }
        .sheet(item: $editingRule) { rule in
            AutoKillRuleEditor(rule: rule) { updated in
                if let index = rules.firstIndex(where: { $0.id == updated.id }) {
                    rules[index] = updated
                }
            }
        }
    }

    private func ruleRow(_ rule: AutoKillRule) -> some View {
        SettingsRowContainer {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        StatusDot(color: rule.isEnabled ? Theme.Colors.statusSuccess : .secondary)
                        Text(rule.name.isEmpty ? "未命名规则" : rule.name)
                            .fontWeight(.medium)
                    }
                    HStack(spacing: 8) {
                        if !rule.processPattern.isEmpty {
                            Text("进程：\(rule.processPattern)")
                        }
                        if rule.port > 0 {
                            Text("端口：\(rule.port)")
                        }
                        Text("超时：\(rule.timeoutMinutes) 分钟")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        editingRule = rule
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)

                    Button {
                        rules.removeAll { $0.id == rule.id }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Rule Editor

struct AutoKillRuleEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var rule: AutoKillRule
    let onSave: (AutoKillRule) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("编辑自动结束规则")
                .font(.headline)
                .padding(.top, 20)

            Form {
                TextField("规则名称", text: $rule.name)

                Section("匹配条件") {
                    TextField("进程模式（如 node*, python*）", text: $rule.processPattern)
                    TextField("端口（0 = 任意）", value: $rule.port, format: .number)
                }

                Section("行为") {
                    Stepper("超时：\(rule.timeoutMinutes) 分钟", value: $rule.timeoutMinutes, in: 1...1440)
                    Toggle("结束前通知", isOn: $rule.notifyBeforeKill)
                    Toggle("已启用", isOn: $rule.isEnabled)
                }
            }
            .formStyle(.grouped)
            .frame(minHeight: 280)

            // Actions
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("保存") {
                    onSave(rule)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(rule.processPattern.isEmpty && rule.port == 0)
            }
            .padding(20)
        }
        .frame(width: 420)
    }
}
