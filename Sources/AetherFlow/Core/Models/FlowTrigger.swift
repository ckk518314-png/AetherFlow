import Foundation

enum FlowTriggerType: String, Codable, CaseIterable {
    case timeOfDay      // 定时
    case calendarEvent  // 日历事件
    case reminderDue    // 提醒到期
    case healthSample   // 健康数据变化
    case homeKitState   // HomeKit 配件状态
    case location       // 地理位置
    case appOpen        // 打开 App
    case widgetTap      // 桌面小组件点击
    case siriShortcut   // Siri 捷径
    case manual         // 手动触发
}

struct FlowTrigger: Codable, Identifiable {
    let id: UUID
    var type: FlowTriggerType
    var name: String
    var configuration: [String: String]

    init(
        id: UUID = UUID(),
        type: FlowTriggerType,
        name: String,
        configuration: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.configuration = configuration
    }

    // MARK: - Convenience

    static func time(hour: Int, minute: Int) -> FlowTrigger {
        FlowTrigger(
            type: .timeOfDay,
            name: "每天 \(String(format: "%02d:%02d", hour, minute))",
            configuration: ["hour": "\(hour)", "minute": "\(minute)"]
        )
    }

    static func calendar(matching keyword: String) -> FlowTrigger {
        FlowTrigger(
            type: .calendarEvent,
            name: "日历: \(keyword)",
            configuration: ["keyword": keyword]
        )
    }

    static func health(_ identifier: String, threshold: Double) -> FlowTrigger {
        FlowTrigger(
            type: .healthSample,
            name: "健康数据",
            configuration: ["identifier": identifier, "threshold": "\(threshold)"]
        )
    }

    static let manual = FlowTrigger(type: .manual, name: "手动触发")
}
