import XCTest
@testable import AetherFlow

final class FlowEngineTests: XCTestCase {

    func testFlowStoreAddAndDelete() async throws {
        let store = FlowStore()
        let flow = FlowDefinition(
            name: "测试流程",
            trigger: .manual,
            steps: [.notification(title: "test", body: "body")]
        )

        XCTAssertEqual(store.flows.count, 0)
        store.addFlow(flow)
        XCTAssertEqual(store.flows.count, 1)
        store.deleteFlow(flow)
        XCTAssertEqual(store.flows.count, 0)
    }

    func testFlowStoreToggle() {
        let store = FlowStore()
        let flow = FlowDefinition(name: "toggle", trigger: .manual)
        store.addFlow(flow)

        XCTAssertTrue(store.flows[0].isEnabled)
        store.toggleFlow(flow)
        XCTAssertFalse(store.flows[0].isEnabled)
    }

    func testConditionEvaluation() {
        var condition = FlowCondition(field: "steps", op: .greaterThan, value: "5000")
        XCTAssertTrue(condition.evaluate(context: ["steps": "8000"]))
        XCTAssertFalse(condition.evaluate(context: ["steps": "3000"]))

        condition = FlowCondition(field: "status", op: .equals, value: "ok")
        XCTAssertTrue(condition.evaluate(context: ["status": "ok"]))
        XCTAssertFalse(condition.evaluate(context: ["status": "error"]))

        condition = FlowCondition(field: "title", op: .contains, value: "会议")
        XCTAssertTrue(condition.evaluate(context: ["title": "项目会议通知"]))
        XCTAssertFalse(condition.evaluate(context: ["title": "午餐"]))

        condition = FlowCondition(field: "name", op: .isEmpty, value: "")
        XCTAssertTrue(condition.evaluate(context: [:]))
        XCTAssertTrue(condition.evaluate(context: ["name": ""]))
        XCTAssertFalse(condition.evaluate(context: ["name": "xxx"]))
    }

    func testFlowTriggerFactory() {
        let timeTrigger = FlowTrigger.time(hour: 9, minute: 30)
        XCTAssertEqual(timeTrigger.type, .timeOfDay)
        XCTAssertEqual(timeTrigger.configuration["hour"], "9")
        XCTAssertEqual(timeTrigger.configuration["minute"], "30")
    }

    func testRunHistoryCap() {
        let store = FlowStore()
        let flowID = UUID()

        for i in 0..<600 {
            store.recordRun(flowID: flowID, success: true, output: "run \(i)")
        }
        XCTAssertEqual(store.runHistory.count, 500)
    }
}
