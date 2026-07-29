import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "⚡️")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: Date(), emoji: "⚡️"))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entries = [SimpleEntry(date: Date(), emoji: "⚡️")]
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct AetherFlowWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .font(.title)
                .foregroundColor(.accentColor)
            Text("AetherFlow")
                .font(.caption)
                .bold()
            Text("点击运行流程")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct AetherFlowWidget: Widget {
    let kind: String = "AetherFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AetherFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AetherFlow")
        .description("一键触发自动化流程")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
