import Foundation

struct FlowCondition: Codable {
    var field: String
    var op: ComparisonOperator
    var value: String

    enum ComparisonOperator: String, Codable, CaseIterable {
        case equals = "=="
        case notEquals = "!="
        case greaterThan = ">"
        case lessThan = "<"
        case contains = "contains"
        case isEmpty = "is_empty"
        case isNotEmpty = "is_not_empty"
    }

    func evaluate(context: [String: Any]) -> Bool {
        switch op {
        case .isEmpty:
            return (context[field] as? String)?.isEmpty ?? true
        case .isNotEmpty:
            return !((context[field] as? String)?.isEmpty ?? true)
        default:
            guard let fieldValue = context[field] as? String else { return false }
            switch op {
            case .equals:    return fieldValue == value
            case .notEquals: return fieldValue != value
            case .contains:  return fieldValue.contains(value)
            case .greaterThan:
                guard let a = Double(fieldValue), let b = Double(value) else { return false }
                return a > b
            case .lessThan:
                guard let a = Double(fieldValue), let b = Double(value) else { return false }
                return a < b
            default: return false
            }
        }
    }
}
