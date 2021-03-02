//
//  ScanInto.swift
//  CombineExt
//
//  Created by Joe Walsh on 8/19/20.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// Reduces the values of this publisher and emits the accumulated value every time this publisher emits a value.
    /// If this publisher fails the returned publisher will fail.
    ///
    /// - Parameters:
    ///   - initialResult: The value to use as the initial accumulating value.
    ///   - updateAccumulatingResult: A closure that updates the accumulating value with the next value
    /// - Returns: A publisher that emits the results reduced into `initialResult` using the `nextPartialResult` closure any time this publisher emits a value.
    func scan<T>(into initialResult: T, _ nextPartialResult: @escaping (inout T, Output) -> Void) -> AnyPublisher<T, Failure> {
        var seed = initialResult
        let lock = NSRecursiveLock()
        return map { current -> T in
            lock.lock()
            defer {
                lock.unlock()
            }
            nextPartialResult(&seed, current)
            return seed
        }
        .eraseToAnyPublisher()
    }

    /// Reduces the values of this publisher and emits the accumulated value every time this publisher emits a value.
    /// If this publisher fails or the nextPartialResult closure throws an error, the returned publisher will fail.
    ///
    /// - Parameters:
    ///   - initialResult: The value to use as the initial accumulating value.
    ///   - updateAccumulatingResult: A closure that updates the accumulating value with the next value
    /// - Returns: A publisher that emits the results reduced into `initialResult` using the `nextPartialResult` closure any time this publisher emits a value.
    func tryScan<T>(into initialResult: T, _ nextPartialResult: @escaping (inout T, Output) throws -> Void) -> AnyPublisher<T, Error> {
        var seed = initialResult
        let lock = NSRecursiveLock()
        return tryMap { current -> T in
            lock.lock()
            defer {
                lock.unlock()
            }
            try nextPartialResult(&seed, current)
            return seed
        }
        .eraseToAnyPublisher()
    }
}
#endif
