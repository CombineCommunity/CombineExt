//
//  PrefixDuration.swift
//  CombineExt
//
//  Created by David Ohayon and Jasdev Singh on 24/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine
import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// Republishes elements for a specified duration.
    ///
    /// - parameters:
    ///   - duration: The time interval during which to accept value or completion events (in seconds).
    ///   - tolerance: The tolerance the underlying timer.
    ///   - runLoop: The run loop for the underlying timer.
    ///   - mode: The run loop mode for the underlying timer.
    ///   - options: The run loop scheduler options for the underlying timer.
    ///
    /// - returns: A publisher that republishes up to the specified duration.
    func prefix(duration: TimeInterval,
                tolerance: TimeInterval? = nil,
                on runLoop: RunLoop = .main,
                in mode: RunLoop.Mode = .default,
                options: RunLoop.SchedulerOptions? = nil) -> Publishers.PrefixUntilOutput<Self, AnyPublisher<Void, Never>> {
        prefix(untilOutputFrom: Timer.publish(every: duration, tolerance: tolerance, on: runLoop, in: mode, options: options)
            .autoconnect()
            .map { _ in }
            .eraseToAnyPublisher())
    }
}
#endif
