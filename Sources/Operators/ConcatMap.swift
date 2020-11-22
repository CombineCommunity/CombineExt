//
//  ConcatMap.swift
//  CombineExt
//
//  Created by Daniel Peter on 22/11/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// Transforms an output value into a new publisher, and flattens the stream of events from these multiple upstream publishers to appear as if they were coming from a single stream of events.
    ///
    /// Mapping to a new publisher will keep the subscription to the previous one alive until it completes and only then subscribe to the new one. This also means that all values sent by the new publisher are not forwarded as long as the previous one hasn't completed.
    ///
    /// - parameter transform: A transform to apply to each emitted value, from which you can return a new Publisher
    ///
    /// - returns: A publisher emitting the values of all emitted publishers in order.
    func concatMap<T, P>(
        _ transform: @escaping (Self.Output) -> P
    ) -> Publishers.FlatMap<P, Self> where T == P.Output, P: Publisher, Self.Failure == P.Failure {
        flatMap(maxPublishers: .max(1), transform)
    }
}
#endif
