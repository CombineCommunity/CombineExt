//
//  PrefixDuration.swift
//  CombineExt
//
//  Created by David Ohayon and Jasdev Singh on 24/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine
import Foundation

public extension Publisher {
    /// Prefixes `self` for a length of time specified by `duration` (in seconds). Any value or completion events are sent downstream prior to the `duration` deadline. After then, a `.finished` event is fired and all subsequent value or completion events from `self` are ignored.
    ///
    /// - parameters:
    ///   - duration: The time interval during which to accept value or completion events (in seconds).
    ///   - tolerance: The tolerance the underlying timer.
    ///   - runLoop: The run loop for the underlying timer.
    ///   - mode: The run loop mode for the underlying timer.
    ///   - options: The run loop scheduler options for the underlying timer.
    ///
    /// - returns: A publisher that prefixes for a `duration` length of time and then finishes normally, if it hasn’t already before then.
    func prefix(duration: TimeInterval,
                tolerance: TimeInterval? = nil,
                on runLoop: RunLoop = .main,
                in mode: RunLoop.Mode = .default,
                options: RunLoop.SchedulerOptions? = nil) -> Publishers.PrefixUntilOutput<Self, Publishers.Autoconnect<Timer.TimerPublisher>> {
        prefix(untilOutputFrom: Timer.publish(every: duration, tolerance: tolerance, on: runLoop, in: mode, options: options).autoconnect())
    }
}
