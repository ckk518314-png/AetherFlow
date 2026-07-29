import Foundation

struct FlowDefinition: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var icon: String
    var isEnabled: Bool
    var trigger: FlowTrigger
    var steps: [FlowStep]
    var createdAt: Date
    var lastRunAt: Date?
    var runCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        icon: String = "arrow.triangle.branch",
        isEnabled: Bool = true,
        trigger: FlowTrigger,
        steps: [FlowStep] = [],
        createdAt: Date = Date(),
        lastRunAt: Date? = nil,
        runCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.isEnabled = isEnabled
        self.trigger = trigger
        self.steps = steps
        self.createdAt = createdAt
        self.lastRunAt = lastRunAt
        self.runCount = runCount
    }
}
