import SwiftUI
import UserNotifications

struct FlowsView: View {
    @EnvironmentObject var store: FlowStore
    @EnvironmentObject var engine: FlowEngine
    @State private var showEditor = false
    @State private var editingFlow: FlowDefinition?

    var body: some View {
        List {
            if store.flows.isEmpty {
                ContentUnavailableView(
                    "暂无自动化流程",
                    systemImage: "arrow.triangle.branch",
                    description: Text("点击右上角 + 创建你的第一个流程")
                )
            }

            ForEach(store.flows) { flow in
                FlowRow(flow: flow)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.deleteFlow(flow)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            Task { await executeFlow(flow) }
                        } label: {
                            Label("执行", systemImage: "play.fill")
                        }
                        .tint(.green)
                    }
                    .onTapGesture {
                        editingFlow = flow
                        showEditor = true
                    }
            }
        }
        .navigationTitle("AetherFlow")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editingFlow = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            FlowEditorView(editFlow: editingFlow) { newFlow in
                if let existing = editingFlow, let idx = store.flows.firstIndex(where: { $0.id == existing.id }) {
                    store.flows[idx] = newFlow
                    store.saveFlows()
                } else {
                    store.addFlow(newFlow)
                }
                showEditor = false
            }
        }
    }

    private func executeFlow(_ flow: FlowDefinition) async {
        let result = await engine.execute(flow)

        let content = UNMutableNotificationContent()
        content.title = result.success ? "流程完成" : "流程失败"
        content.body = flow.name
        content.sound = .default
        UNUserNotificationCenter.current().add(
            .init(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }
}

struct FlowRow: View {
    let flow: FlowDefinition

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: flow.icon)
                .font(.title2)
                .foregroundColor(flow.isEnabled ? .accentColor : .gray)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(flow.name)
                    .font(.headline)
                    .foregroundColor(flow.isEnabled ? .primary : .secondary)

                HStack(spacing: 8) {
                    Text(flow.trigger.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(flow.steps.count) 步")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if flow.runCount > 0 {
                        Text("运行 \(flow.runCount) 次")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if !flow.isEnabled {
                Image(systemName: "pause.circle")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}
