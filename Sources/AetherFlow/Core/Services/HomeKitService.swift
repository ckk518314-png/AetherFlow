import HomeKit
import Combine

final class HomeKitService: NSObject, ObservableObject {
    private let manager = HMHomeManager()

    @Published var homes: [HMHome] = []
    @Published var authorizationStatus: HMHomeManagerAuthorizationStatus = .determined(0)

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            continuation.resume(returning: manager.authorizationStatus.contains(.authorized))
        }
    }

    func allAccessories() -> [HMAccessory] {
        homes.flatMap { $0.accessories }
    }

    func findAccessory(by uuid: String) -> HMAccessory? {
        allAccessories().first { $0.uniqueIdentifier.uuidString == uuid }
    }

    func controlAccessory(
        uuid: String,
        characteristicType: String,
        value: Any
    ) async throws {
        guard let accessory = findAccessory(by: uuid) else {
            throw HomeKitError.accessoryNotFound
        }
        for service in accessory.services {
            for characteristic in service.characteristics {
                if characteristic.characteristicType == characteristicType {
                    try await characteristic.writeValue(value)
                    return
                }
            }
        }
        throw HomeKitError.characteristicNotFound
    }

    func executeScene(_ scene: HMScene) async throws {
        let home = scene.home
        try await home.executeActionSet(scene)
    }

    enum HomeKitError: LocalizedError {
        case accessoryNotFound
        case characteristicNotFound

        var errorDescription: String? {
            switch self {
            case .accessoryNotFound:     return "未找到配件"
            case .characteristicNotFound: return "未找到该特征"
            }
        }
    }
}

extension HomeKitService: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        homes = manager.homes
    }
}
