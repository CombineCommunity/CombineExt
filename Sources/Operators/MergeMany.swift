//
//  MergeMany.swift
//  CombineExt
//
//  Created by Joe Walsh on 8/17/20.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

// MARK: - Collection Helpers
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Collection where Element: Publisher {
    /// Merge a collection of publishers with the same output and failure types into a single publisher.
    /// If any of the publishers in the collection fails, the returned publisher will also fail.
    /// The returned publisher will not finish until all of the merged publishers finish.
    ///
    /// - Returns: A type-erased publisher that emits all events from the publishers in the collection.
    func merge() -> AnyPublisher<Self.Element.Output, Self.Element.Failure> {
        switch count {
        case 0:
            return Empty().eraseToAnyPublisher()
        case 1:
            return self[startIndex].eraseToAnyPublisher()
        default:
            let secondIndex = index(after: startIndex)
            let thirdIndex = index(after: secondIndex)
            let initial = self[startIndex].merge(with: self[secondIndex])
            return self[thirdIndex...].reduce(initial) { result, publisher -> Publishers.MergeMany<Self.Element> in
                return result.merge(with: publisher)
            }.eraseToAnyPublisher()
        }
    }
}
#endif
