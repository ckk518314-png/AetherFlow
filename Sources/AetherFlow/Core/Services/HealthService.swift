import HealthKit
import Combine

final class HealthService: ObservableObject {
    private let store: HKHealthStore

    @Published var authorizationStatus: HKAuthorizationRequestStatus = .unknown

    init() {
        guard HKHealthStore.isHealthDataAvailable() else {
            fatalError("HealthKit 不可用于此设备")
        }
        store = HKHealthStore()
    }

    func requestAccess(
        readTypes: Set<HKObjectType>,
        writeTypes: Set<HKSampleType>
    ) async throws -> Bool {
        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
    }

    func requestDefaultPermissions() async throws {
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: - Query

    func querySamples(
        identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date = Date()
    ) async -> [HKQuantitySample] {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
            }
            store.execute(query)
        }
    }

    func todayStepCount() async -> Double {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let samples = await querySamples(identifier: .stepCount, from: startOfDay)
        return samples.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.count()) }
    }

    func startWorkout(
        activityType: HKWorkoutActivityType,
        startDate: Date = Date()
    ) -> HKWorkoutSession? {
        guard let configuration = configureWorkout(activityType: activityType) else { return nil }
        return nil
    }

    private func configureWorkout(activityType: HKWorkoutActivityType) -> HKWorkoutConfiguration? {
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = .unknown
        return config
    }
}
