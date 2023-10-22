import Foundation

extension Array {
    func get(_ index: Int) -> Element? {
        if self.count > index {
            return self[index]
        } else {
            return nil
        }
    }
}

extension Collection {
    func byMovingMatchingItemsToFront(_ block: (Element) -> Bool) -> [Element] {
        var matches = [Element]()
        var nonMatches = [Element]()
        for item in self {
            if block(item) {
                matches.append(item)
            } else {
                nonMatches.append(item)
            }
        }
        return matches + nonMatches
    }
}
