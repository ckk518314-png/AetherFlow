import Foundation
import Combine

final class FlowEngine: ObservableObject {
    private let store: FlowStore
    private let calendar: CalendarService
    private let reminders: ReminderService
    private let health: HealthService
    private let homeKit: HomeKitService

    @Published var isRunning = false
    @Published var currentStepName: String = ""
    @Published var runLog: [String] = []

    init(
        store: FlowStore,
        calendar: CalendarService,
        reminders: ReminderService,
        health: HealthService,
        homeKit: HomeKitService
    ) {
        self.store = store
        self.calendar = calendar
        self.reminders = reminders
        self.health = health
        self.homeKit = homeKit
    }

    // MARK: - Execute Flow

    func execute(_ flow: FlowDefinition) async -> FlowResult {
        guard flow.isEnabled else {
            return FlowResult(success: false, output: "流程已禁用")
        }
        guard !flow.steps.isEmpty else {
            return FlowResult(success: false, output: "流程没有步骤")
        }

        await MainActor.run {
            isRunning = true
            runLog = ["开始: \(flow.name)"]
        }

        var context: [String: Any] = [:]
        var allSucceeded = true
        let totalSteps = flow.steps.count

        for (index, step) in flow.steps.enumerated() {
            await MainActor.run {
                currentStepName = "[\(index + 1)/\(totalSteps)] \(step.name)"
            }

            // 条件判断
            if let condition = step.conditionBlock {
                let pass = condition.evaluate(context: context)
                if !pass {
                    await appendLog("[跳过] \(step.name) - 条件不满足")
                    continue
                }
            }

            let result = await executeStep(step, context: &context)
            if result.success {
                await appendLog("[通过] \(step.name)")
            } else {
                await appendLog("[失败] \(step.name): \(result.output)")
                allSucceeded = false
                break
            }

            // 步骤间的延迟
            if let delayParam = step.parameters.first(where: { $0.key == "seconds" }),
               step.type == .delay,
               let seconds = TimeInterval(delayParam.value) {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
        }

        await MainActor.run {
            isRunning = false
        }

        let output = runLog.joined(separator: "\n")
        store.recordRun(flowID: flow.id, success: allSucceeded, output: output)

        return FlowResult(success: allSucceeded, output: output)
    }

    // MARK: - Step Execution

    private func executeStep(_ step: FlowStep, context: inout [String: Any]) async -> Result {
        switch step.type {
        case .sendNotification:
            return await notifyStep(step)
        case .addCalendarEvent:
            return await addCalendarEventStep(step)
        case .searchCalendarEvents:
            return await searchCalendarStep(step)
        case .removeCalendarEvent:
            return await removeCalendarStep(step)
        case .addReminder:
            return await addReminderStep(step)
        case .completeReminder:
            return await completeReminderStep(step)
        case .removeReminder:
            return await removeReminderStep(step)
        case .readHealthData:
            return await readHealthStep(step, context: &context)
        case .controlAccessory:
            return await controlAccessoryStep(step)
        case .delay:
            return Result(success: true, output: "OK")
        case .openURL:
            return await openURLStep(step)
        case .httpRequest:
            return await httpRequestStep(step)
        case .condition:
            return Result(success: true, output: "条件检查通过")
        default:
            return Result(success: false, output: "不支持的步骤类型: \(step.type.rawValue)")
        }
    }

    // MARK: - Steps

    private func notifyStep(_ step: FlowStep) async -> Result {
        let title = step.parameters.first(where: { $0.key == "title" })?.value ?? "AetherFlow"
        let body = step.parameters.first(where: { $0.key == "body" })?.value ?? ""
        await MainActor.run {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }
        return Result(success: true, output: "通知已发送")
    }

    private func addCalendarEventStep(_ step: FlowStep) async -> Result {
        do {
            let granted = try await calendar.requestAccess()
            guard granted else { return Result(success: false, output: "日历权限未授权") }

            let title = step.parameters.first(where: { $0.key == "title" })?.value ?? "新事件"
            let startStr = step.parameters.first(where: { $0.key == "startDate" })?.value ?? ""
            let durationStr = step.parameters.first(where: { $0.key == "duration" })?.value ?? "3600"

            let formatter = ISO8601DateFormatter()
            let startDate = formatter.date(from: startStr) ?? Date()
            let duration = TimeInterval(durationStr) ?? 3600

            _ = try calendar.createEvent(
                title: title,
                startDate: startDate,
                endDate: startDate.addingTimeInterval(duration)
            )
            return Result(success: true, output: "日历事件已创建: \(title)")
        } catch {
            return Result(success: false, output: error.localizedDescription)
        }
    }

    private func searchCalendarStep(_ step: FlowStep) async -> Result {
        do {
            let granted = try await calendar.requestAccess()
            guard granted else { return Result(success: false, output: "日历权限未授权") }

            let keyword = step.parameters.first(where: { $0.key == "keyword" })?.value
            let events = await calendar.searchEvents(keyword: keyword)
            let titles = events.map { $0.title ?? "(无标题)" }.joined(separator: ", ")
            return Result(success: true, output: "找到 \(events.count) 个事件: \(titles)")
        } catch {
            return Result(success: false, output: error.localizedDescription)
        }
    }

    private func removeCalendarStep(_ step: FlowStep) async -> Result {
        return Result(success: false, output: "需要指定事件 ID，暂未实现")
    }

    private func addReminderStep(_ step: FlowStep) async -> Result {
        do {
            let granted = try await reminders.requestAccess()
            guard granted else { return Result(success: false, output: "提醒权限未授权") }

            let title = step.parameters.first(where: { $0.key == "title" })?.value ?? "新提醒"
            _ = try reminders.createReminder(title: title)
            return Result(success: true, output: "提醒已创建: \(title)")
        } catch {
            return Result(success: false, output: error.localizedDescription)
        }
    }

    private func completeReminderStep(_ step: FlowStep) async -> Result {
        do {
            let granted = try await reminders.requestAccess()
            guard granted else { return Result(success: false, output: "提醒权限未授权") }
            let list = await reminders.fetchReminders(completed: false)
            guard let first = list.first else {
                return Result(success: false, output: "没有待完成的提醒")
            }
            try reminders.completeReminder(first)
            return Result(success: true, output: "提醒已完成: \(first.title ?? "")")
        } catch {
            return Result(success: false, output: error.localizedDescription)
        }
    }

    private func removeReminderStep(_ step: FlowStep) async -> Result {
        do {
            let granted = try await reminders.requestAccess()
            guard granted else { return Result(success: false, output: "提醒权限未授权") }
            let list = await reminders.fetchReminders(completed: false)
            guard let first = list.first else { return Result(success: false, output: "没有可删除的提醒") }
            try reminders.removeReminder(first)
            return Result(success: true, output: "提醒已删除")
        } catch {
            return Result(success: false, output: error.localizedDescription)
        }
    }

    private func readHealthStep(_ step: FlowStep, context: inout [String: Any]) async -> Result {
        let identifier = step.parameters.first(where: { $0.key == "identifier" })?.value
        let steps = await health.todayStepCount()
        context["steps"] = steps
        return Result(success: true, output: "今日步数: \(Int(steps))")
    }

    private func controlAccessoryStep(_ step: FlowStep) async -> Result {
        do {
            let uuid = step.parameters.first(where: { $0.key == "accessoryUUID" })?.value ?? ""
            let characteristic = step.parameters.first(where: { $0.key == "characteristic" })?.value ?? ""
            let value = step.parameters.first(where: { $0.key == "value" })?.value ?? ""
            try await homeKit.controlAccessory(uuid: uuid, characteristicType: characteristic, value: value)
            return Result(success: true, output: "配件控制完成")
        } catch {
            return Result(success: false, output: error.localizedDescription)
        }
    }

    private func openURLStep(_ step: FlowStep) async -> Result {
        let urlStr = step.parameters.first(where: { $0.key == "url" })?.value ?? ""
        guard let url = URL(string: urlStr) else {
            return Result(success: false, output: "无效 URL: \(urlStr)")
        }
        await MainActor.run { UIApplication.shared.open(url) }
        return Result(success: true, output: "已打开: \(url.absoluteString)")
    }

    private func httpRequestStep(_ step: FlowStep) async -> Result {
        let urlStr = step.parameters.first(where: { $0.key == "url" })?.value ?? ""
        let method = step.parameters.first(where: { $0.key == "method" })?.value ?? "GET"
        let body = step.parameters.first(where: { $0.key == "body" })?.value ?? ""
        guard let url = URL(string: urlStr) else {
            return Result(success: false, output: "无效 URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if !body.isEmpty {
            request.httpBody = body.data(using: .utf8)
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let text = String(data: data, encoding: .utf8) ?? ""
            return Result(success: (200...299).contains(code), output: "HTTP \(code): \(text.prefix(200))")
        } catch {
            return Result(success: false, output: error.localizedDescription)
        }
    }

    // MARK: - Helpers

    @MainActor
    private func appendLog(_ message: String) {
        runLog.append(message)
    }

    struct Result {
        let success: Bool
        let output: String
    }

    struct FlowResult: Codable {
        let success: Bool
        let output: String
    }
}

extension FlowEngine.Result {
    init(success: Bool, output: String) {
        self.success = success
        self.output = output
    }
}
