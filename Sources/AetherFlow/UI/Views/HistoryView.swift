import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: FlowStore

    var body: some View {
        List {
            if store.runHistory.isEmpty {
                ContentUnavailableView(
                    "暂无运行记录",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("执行流程后记录会出现在这里")
                )
            }

            ForEach(store.runHistory) { record in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(record.success ? .green : .red)
                        Text(record.success ? "成功" : "失败")
                            .font(.headline)
                        Spacer()
                        Text(record.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let flow = store.flows.first(where: { $0.id == record.flowID }) {
                        Text(flow.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !record.output.isEmpty {
                        Text(record.output)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("运行历史")
    }
}
