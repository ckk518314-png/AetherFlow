import SwiftUI

@main
struct AetherFlowApp: App {
    @StateObject private var store = FlowStore()
    @StateObject private var calendar = CalendarService()
    @StateObject private var reminders = ReminderService()
    @StateObject private var health = HealthService()
    @StateObject private var homeKit = HomeKitService()
    @StateObject private var engine: FlowEngine

    init() {
        let store = FlowStore()
        let calendar = CalendarService()
        let reminders = ReminderService()
        let health = HealthService()
        let homeKit = HomeKitService()

        let engine = FlowEngine(
            store: store,
            calendar: calendar,
            reminders: reminders,
            health: health,
            homeKit: homeKit
        )

        _store = StateObject(wrappedValue: store)
        _calendar = StateObject(wrappedValue: calendar)
        _reminders = StateObject(wrappedValue: reminders)
        _health = StateObject(wrappedValue: health)
        _homeKit = StateObject(wrappedValue: homeKit)
        _engine = StateObject(wrappedValue: engine)

        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(calendar)
                .environmentObject(reminders)
                .environmentObject(health)
                .environmentObject(homeKit)
                .environmentObject(engine)
        }
    }
}
