//
//  Partition.swift
//  CombineExt
//
//  Created by Shai Mishali on 14/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// A partitioned publisher
    typealias Partition = AnyPublisher<Output, Failure>

    /// Partition a publisher's values into two separate publishers of values that match, and don't match, the provided predicate.
    ///
    /// - parameter predicate: A predicate used to filter matching and non-matching values.
    ///
    /// - returns: A tuple of two publishers of values that match, and don't match, the provided predicate.
    ///
    /// - note: The source publisher is `share()`d by default so resources are shared between the partitioned publshers
    func partition(_ predicate: @escaping (Output) -> Bool) -> (matches: Partition, nonMatches: Partition) {
        let source = map { ($0, predicate($0)) }.share()

        let hits = source.compactMap { $0.1 ? $0.0 : nil }.eraseToAnyPublisher()
        let misses = source.compactMap { !$0.1 ? $0.0 : nil }.eraseToAnyPublisher()

        return (hits, misses)
    }
}
#endif
