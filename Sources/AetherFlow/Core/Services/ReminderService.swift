import EventKit
import Combine

final class ReminderService: ObservableObject {
    private let store = EKEventStore()

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    func requestAccess() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        await MainActor.run { authorizationStatus = status }

        if status == .notDetermined {
            let granted = try await store.requestAccess(to: .reminder)
            await MainActor.run { authorizationStatus = granted ? .fullAccess : .denied }
            return granted
        }
        return status == .fullAccess || status == .authorized
    }

    func fetchReminders(
        completed: Bool = false,
        in calendar: EKCalendar? = nil
    ) async -> [EKReminder] {
        let calendars: [EKCalendar] = calendar.map { [$0] } ?? store.calendars(for: .reminder)
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: completed ? nil : calendars
        )
        return await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                var results = reminders ?? []
                if completed {
                    results = results.filter { $0.isCompleted }
                }
                continuation.resume(returning: results)
            }
        }
    }

    func createReminder(
        title: String,
        notes: String? = nil,
        dueDate: DateComponents? = nil,
        priority: Int = 0,
        calendar: EKCalendar? = nil
    ) throws -> EKReminder {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        reminder.dueDateComponents = dueDate
        reminder.priority = priority
        reminder.calendar = calendar ?? store.defaultCalendarForNewReminders()
        try store.save(reminder, commit: true)
        return reminder
    }

    func completeReminder(_ reminder: EKReminder) throws {
        reminder.isCompleted = true
        try store.save(reminder, commit: true)
    }

    func removeReminder(_ reminder: EKReminder) throws {
        try store.remove(reminder, commit: true)
    }
}
