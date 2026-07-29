import Foundation
import EventKit
import HomeKit
import HealthKit

enum FlowStepType: String, Codable, CaseIterable {
    // 日历
    case addCalendarEvent
    case removeCalendarEvent
    case searchCalendarEvents

    // 提醒
    case addReminder
    case completeReminder
    case removeReminder

    // 健康
    case readHealthData
    case writeHealthData
    case startWorkout

    // HomeKit
    case controlAccessory
    case readSensor
    case setScene

    // 通用
    case sendNotification
    case openURL
    case runShortcut
    case delay

    // 脚本
    case runJavaScript
    case httpRequest

    // 条件
    case condition
}

struct FlowStepParameter: Codable {
    var key: String
    var value: String
    var label: String
}

struct FlowStep: Codable, Identifiable {
    let id: UUID
    var type: FlowStepType
    var name: String
    var parameters: [FlowStepParameter]
    var conditionBlock: FlowCondition?

    init(
        id: UUID = UUID(),
        type: FlowStepType,
        name: String,
        parameters: [FlowStepParameter] = [],
        condition: FlowCondition? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.parameters = parameters
        self.conditionBlock = condition
    }

    // MARK: - Factory

    static func notification(title: String, body: String) -> FlowStep {
        FlowStep(
            type: .sendNotification,
            name: "通知: \(title)",
            parameters: [
                FlowStepParameter(key: "title", value: title, label: "标题"),
                FlowStepParameter(key: "body", value: body, label: "内容")
            ]
        )
    }

    static func calendar(title: String, startDate: Date, duration: TimeInterval) -> FlowStep {
        FlowStep(
            type: .addCalendarEvent,
            name: "日历: \(title)",
            parameters: [
                FlowStepParameter(key: "title", value: title, label: "标题"),
                FlowStepParameter(key: "startDate", value: ISO8601DateFormatter().string(from: startDate), label: "开始"),
                FlowStepParameter(key: "duration", value: "\(duration)", label: "时长")
            ]
        )
    }

    static func homeKit(accessoryUUID: String, characteristic: String, value: String) -> FlowStep {
        FlowStep(
            type: .controlAccessory,
            name: "HomeKit 控制",
            parameters: [
                FlowStepParameter(key: "accessoryUUID", value: accessoryUUID, label: "配件"),
                FlowStepParameter(key: "characteristic", value: characteristic, label: "特征"),
                FlowStepParameter(key: "value", value: value, label: "值")
            ]
        )
    }

    static func delay(seconds: TimeInterval) -> FlowStep {
        FlowStep(
            type: .delay,
            name: "等待 \(Int(seconds))s",
            parameters: [FlowStepParameter(key: "seconds", value: "\(seconds)", label: "秒数")]
        )
    }
}
