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
    func merge() -> AnyPublisher<Element.Output, Element.Failure> {
		Publishers.MergeMany(self).eraseToAnyPublisher()
    }
}
#endif
