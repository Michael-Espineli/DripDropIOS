//
//  Array+ShoppingHelpers.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/26/26.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }

        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension Array where Element == ShoppingListItem {
    func dedupedByShoppingItemId() -> [ShoppingListItem] {
        var seen: Set<String> = []
        var result: [ShoppingListItem] = []

        for item in self {
            guard !seen.contains(item.id) else { continue }

            seen.insert(item.id)
            result.append(item)
        }

        return result
    }

    func sortedForShoppingPrep() -> [ShoppingListItem] {
        self.sorted { lhs, rhs in
            if lhs.status.rawValue != rhs.status.rawValue {
                return lhs.status.rawValue < rhs.status.rawValue
            }

            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
