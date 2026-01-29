import Foundation

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Array where Element: Equatable {
    mutating func removeAll(_ item: Element) {
        removeAll { $0 == item }
    }
}
