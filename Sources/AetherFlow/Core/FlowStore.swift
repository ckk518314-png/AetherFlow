import Foundation
import Combine

final class FlowStore: ObservableObject {
    @Published var flows: [FlowDefinition] = []
    @Published var runHistory: [FlowRunRecord] = []

    private let flowsKey = "aetherflow_definitions"
    private let historyKey = "aetherflow_history"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadFlows()
        loadHistory()
    }

    // MARK: - Flows CRUD

    func loadFlows() {
        guard let data = defaults.data(forKey: flowsKey),
              let decoded = try? JSONDecoder().decode([FlowDefinition].self, from: data)
        else { return }
        flows = decoded
    }

    func saveFlows() {
        guard let data = try? JSONEncoder().encode(flows) else { return }
        defaults.set(data, forKey: flowsKey)
    }

    func addFlow(_ flow: FlowDefinition) {
        flows.append(flow)
        saveFlows()
    }

    func updateFlow(_ flow: FlowDefinition) {
        guard let index = flows.firstIndex(where: { $0.id == flow.id }) else { return }
        flows[index] = flow
        saveFlows()
    }

    func deleteFlow(_ flow: FlowDefinition) {
        flows.removeAll { $0.id == flow.id }
        saveFlows()
    }

    func toggleFlow(_ flow: FlowDefinition) {
        guard let index = flows.firstIndex(where: { $0.id == flow.id }) else { return }
        flows[index].isEnabled.toggle()
        saveFlows()
    }

    // MARK: - History

    func loadHistory() {
        guard let data = defaults.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([FlowRunRecord].self, from: data)
        else { return }
        runHistory = decoded
    }

    func saveHistory() {
        guard let data = try? JSONEncoder().encode(runHistory) else { return }
        defaults.set(data, forKey: historyKey)
    }

    func recordRun(flowID: UUID, success: Bool, output: String = "") {
        let record = FlowRunRecord(flowID: flowID, timestamp: Date(), success: success, output: output)
        runHistory.insert(record, at: 0)
        if runHistory.count > 500 {
            runHistory = Array(runHistory.prefix(500))
        }
        saveHistory()
    }
}

struct FlowRunRecord: Codable, Identifiable {
    let id: UUID
    let flowID: UUID
    let timestamp: Date
    let success: Bool
    let output: String

    init(id: UUID = UUID(), flowID: UUID, timestamp: Date, success: Bool, output: String) {
        self.id = id
        self.flowID = flowID
        self.timestamp = timestamp
        self.success = success
        self.output = output
    }
}
