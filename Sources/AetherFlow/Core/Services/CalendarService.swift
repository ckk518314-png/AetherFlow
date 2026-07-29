import EventKit
import Combine

final class CalendarService: ObservableObject {
    private let store = EKEventStore()

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    func requestAccess() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        await MainActor.run { authorizationStatus = status }

        if status == .notDetermined {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            await MainActor.run { authorizationStatus = granted ? .fullAccess : .denied }
            return granted
        }
        return status == .fullAccess || status == .authorized
    }

    func searchEvents(
        keyword: String? = nil,
        from startDate: Date = Date(),
        to endDate: Date? = nil,
        calendars: [EKCalendar]? = nil
    ) async -> [EKEvent] {
        let end = endDate ?? Calendar.current.date(byAdding: .month, value: 3, to: startDate)!
        let predicate = store.predicateForEvents(withStart: startDate, end: end, calendars: calendars)
        var events = store.events(matching: predicate)
        if let kw = keyword, !kw.isEmpty {
            events = events.filter { ($0.title ?? "").localizedCaseInsensitiveContains(kw) }
        }
        return events
    }

    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        notes: String? = nil,
        calendar: EKCalendar? = nil
    ) throws -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = calendar ?? store.defaultCalendarForNewEvents ?? store.calendars(for: .event).first
        try store.save(event, span: .thisEvent)
        return event
    }

    func removeEvent(_ event: EKEvent) throws {
        try store.remove(event, span: .thisEvent)
    }

    func getCalendars() -> [EKCalendar] {
        store.calendars(for: .event)
    }
}
