import SwiftUI

struct FlowEditorView: View {
    let editFlow: FlowDefinition?
    let onSave: (FlowDefinition) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var icon: String = "arrow.triangle.branch"
    @State private var triggerType: FlowTriggerType = .manual
    @State private var steps: [FlowStep] = []

    private let icons = [
        "arrow.triangle.branch", "calendar", "bell", "heart",
        "house", "location", "app", "widget.small",
        "mic", "hand.tap"
    ]

    init(editFlow: FlowDefinition?, onSave: @escaping (FlowDefinition) -> Void) {
        self.editFlow = editFlow
        self.onSave = onSave
        if let flow = editFlow {
            _name = State(initialValue: flow.name)
            _description = State(initialValue: flow.description)
            _icon = State(initialValue: flow.icon)
            _triggerType = State(initialValue: flow.trigger.type)
            _steps = State(initialValue: flow.steps)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section("基本信息") {
                    TextField("流程名称", text: $name)
                    TextField("描述", text: $description)
                }

                // 图标
                Section("图标") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5)) {
                        ForEach(icons, id: \.self) { item in
                            Image(systemName: item)
                                .font(.title)
                                .foregroundColor(icon == item ? .accentColor : .secondary)
                                .padding(8)
                                .background(icon == item ? Color.accentColor.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { icon = item }
                        }
                    }
                }

                // 触发器
                Section("触发器") {
                    Picker("触发方式", selection: $triggerType) {
                        ForEach(FlowTriggerType.allCases, id: \.self) { type in
                            Text(triggerLabel(type)).tag(type)
                        }
                    }
                }

                // 步骤
                Section {
                    if steps.isEmpty {
                        Text("暂无步骤，点击下方添加")
                            .foregroundColor(.secondary)
                    }
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        HStack {
                            Image(systemName: stepIcon(step.type))
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text("步骤 \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(step.name)
                            }
                        }
                    }
                    .onDelete { steps.remove(atOffsets: $0) }

                    Button {
                        addQuickStep()
                    } label: {
                        Label("添加步骤", systemImage: "plus.circle")
                    }
                } header: {
                    Text("步骤 (\(steps.count))")
                } footer: {
                    Text("步骤按顺序执行，遇到失败会中断")
                }
            }
            .navigationTitle(editFlow == nil ? "新建流程" : "编辑流程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let flow = FlowDefinition(
                            id: editFlow?.id ?? UUID(),
                            name: name.isEmpty ? "未命名流程" : name,
                            description: description,
                            icon: icon,
                            isEnabled: editFlow?.isEnabled ?? true,
                            trigger: FlowTrigger(type: triggerType, name: triggerLabel(triggerType)),
                            steps: steps,
                            createdAt: editFlow?.createdAt ?? Date(),
                            lastRunAt: editFlow?.lastRunAt,
                            runCount: editFlow?.runCount ?? 0
                        )
                        onSave(flow)
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func addQuickStep() {
        let presets: [(FlowStepType, String)] = [
            (.sendNotification, "发送通知"),
            (.addCalendarEvent, "添加日历事件"),
            (.addReminder, "添加提醒"),
            (.readHealthData, "读取健康数据"),
            (.controlAccessory, "控制 HomeKit"),
            (.openURL, "打开链接"),
            (.httpRequest, "HTTP 请求"),
            (.delay, "等待")
        ]

        if steps.isEmpty {
            // 默认添加通知步骤
            steps.append(.notification(title: "AetherFlow", body: "自动化流程已触发"))
        } else {
            steps.append(.delay(seconds: 1))
        }
    }

    private func triggerLabel(_ type: FlowTriggerType) -> String {
        switch type {
        case .timeOfDay:     return "定时"
        case .calendarEvent: return "日历事件"
        case .reminderDue:   return "提醒到期"
        case .healthSample:  return "健康数据"
        case .homeKitState:  return "HomeKit 状态"
        case .location:      return "地理位置"
        case .appOpen:       return "打开 App"
        case .widgetTap:     return "小组件点击"
        case .siriShortcut:  return "Siri 捷径"
        case .manual:        return "手动触发"
        }
    }

    private func stepIcon(_ type: FlowStepType) -> String {
        switch type {
        case .addCalendarEvent, .searchCalendarEvents, .removeCalendarEvent: return "calendar"
        case .addReminder, .completeReminder, .removeReminder: return "bell"
        case .readHealthData, .writeHealthData, .startWorkout: return "heart"
        case .controlAccessory, .readSensor, .setScene: return "house"
        case .sendNotification: return "bell.badge"
        case .openURL: return "safari"
        case .runShortcut: return "play.rectangle"
        case .runJavaScript: return "curlybraces"
        case .httpRequest: return "network"
        case .delay: return "clock"
        case .condition: return "questionmark.diamond"
        }
    }
}
