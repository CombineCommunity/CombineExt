//
//  ReduceInto.swift
//  CombineExt
//
//  Created by Joe Walsh on 8/18/20.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// Reduces the results of this publisher into a single publisher that emits the accumulated value when this publisher finishes.
    /// If this publisher fails the returned publisher will fail.
    ///
    /// - Parameters:
    ///   - initialResult: The value to use as the initial accumulating value.
    ///   - updateAccumulatingResult: A closure that updates the accumulating
    ///     value with the next value
    /// - Returns: A publisher that waits until all publishers have finished and emits the results reduced into `initialResult` using the `nextPartialResult` closure
    func reduce<T>(into initialResult: T, _ nextPartialResult: @escaping (inout T, Output) -> Void) -> AnyPublisher<T, Failure> {
        scan(into: initialResult, nextPartialResult)
            .last()
            .eraseToAnyPublisher()
    }

    /// Reduces the results of this publisher into a single publisher that emits the accumulated value when this publisher finishes.
    /// If this publisher fails or the nextPartialResult closure throws an error, the returned publisher will fail.
    ///
    /// - Parameters:
    ///   - initialResult: The value to use as the initial accumulating value.
    ///   - updateAccumulatingResult: A closure that updates the accumulating
    ///     value with the next value
    /// - Returns: A publisher that waits until all publishers have finished and emits the results reduced into `initialResult` using the `nextPartialResult` closure
    func tryReduce<T>(into initialResult: T, _ nextPartialResult: @escaping (inout T, Output) throws -> Void) -> AnyPublisher<T, Error> {
        tryScan(into: initialResult, nextPartialResult)
            .last()
            .eraseToAnyPublisher()
    }
}
#endif
