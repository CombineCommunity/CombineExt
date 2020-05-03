//
//  RemoveAllDuplicates.swift
//  CombineExt
//
//  Created by Jasdev Singh on 21/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Output: Hashable {
    /// De-duplicates _all_ published value events, as opposed
    /// to pairwise with `Publisher.removeDuplicates`.
    ///
    /// - note: It’s important to note that this operator stores all emitted values
    ///         in an in-memory `Set`. So, use this operator with caution, when handling publishers
    ///         that emit a large number of unique value events.
    ///
    /// - returns: A publisher that consumes duplicate values across all previous emissions from upstream.
    func removeAllDuplicates() -> Publishers.Filter<Self> {
        var seen = Set<Output>()
        return filter { incoming in seen.insert(incoming).inserted }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Output: Equatable {
    /// `Publisher.removeAllDuplicates` de-duplicates _all_ published `Hashable`-conforming value events, as opposed to pairwise with `Publisher.removeDuplicates`.
    ///
    /// - note: It’s important to note that this operator stores all emitted values in an in-memory `Array`. So, use
    ///         this operator with caution, when handling publishers that emit a large number of unique value events.
    ///
    /// - returns: A publisher that consumes duplicate values across all previous emissions from upstream.
    func removeAllDuplicates() -> Publishers.Filter<Self> {
        removeAllDuplicates(by: ==)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// De-duplicates _all_ published value events, along the provided `by` comparator, as opposed to pairwise with `Publisher.removeDuplicates(by:)`.
    ///
    /// - parameter by: A comparator to use when determining uniqueness. `Publisher.removeAllDuplicates` will iterate
    ///                 over all seen values applying each known unique value as the first argument to the comparator and the
    ///                 incoming value event as the second, i.e. `by(see, next) -> Bool`. If this comparator is `true` for any
    ///                 seen value, the next incoming value isn’t emitted downstream.
    ///
    /// - note: It’s important to note that this operator stores all emitted values
    ///         in an in-memory `Array`. So, use this operator with caution, when handling publishers
    ///         that emit a large number of unique value events (as per `by`).
    ///
    /// - returns: A publisher that consumes duplicate values across all previous emissions from upstream
    ///            (signaled with `by`).
    func removeAllDuplicates(by comparator: @escaping (Output, Output) -> Bool) -> Publishers.Filter<Self> {
        var seen = [Output]()
        return filter { incoming in
            if seen.contains(where: { comparator($0, incoming) }) {
                return false
            } else {
                seen.append(incoming)
                return true
            }
        }
    }
}
#endif
