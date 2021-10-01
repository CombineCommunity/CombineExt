//
//  RxSwiftExt.swift
//  
//
//  Created by Hugo Saynac on 30/09/2021.
//  Inspired by Anton Efimenko on 17/07/16 on the RxSwiftExt project
//  Copyright © 2020 Combine Community. All rights reserved.

import Foundation
#if canImport(Combine)
import Combine
import SwiftUI

/**
 Specifies how a publisher will be repeated in case of an error.
 */
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public enum RepeatBehavior<Context> where Context: Scheduler {

    /**
     Will be immediately repeated specified number of times.
     - **maxCount:** Maximum number of times to repeat the sequence.
     */
    case immediate (maxCount: UInt)

    /**
     Will be repeated after specified delay specified number of times.
     - **maxCount:** Maximum number of times to repeat the sequence.
     - **time:** time in seconds.
     */
    case delayed (maxCount: UInt, time: Double)

    /**
     Will be repeated specified number of times.
     Delay will be incremented by multiplier after each iteration (multiplier = 0.5 means 50% increment).
     - **maxCount:** Maximum number of times to repeat the sequence.
     - **initial:** initial time in seconds.
     */
    case exponentialDelayed (maxCount: UInt, initial: Double, multiplier: Double)

    /**
     Will be repeated specified number of times. Delay will be calculated by custom closure.
     - **maxCount:** Maximum number of times to repeat the sequence.
     - **delayCaluculator:** a closure that takes the currentRepetition and returns a delay.
     */
    case customTimerDelayed (maxCount: UInt, delayCalculator: (UInt) -> Context.SchedulerTimeType.Stride)
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension RepeatBehavior {
    /**
     Extracts maxCount and calculates delay for current RepeatBehavior
     - parameter currentAttempt: Number of current attempt
     - returns: Tuple with maxCount and calculated delay for provided attempt
     */
    func calculateConditions(_ currentRepetition: UInt) -> (maxCount: UInt, delay: Context.SchedulerTimeType.Stride) {
        switch self {
        case .immediate(let max):
            // if Immediate, return 0.0 as delay
            return (maxCount: max, delay: .zero)
        case .delayed(let max, let time):
            // return specified delay
            return (maxCount: max, delay: .milliseconds(Int(time * 1000)))
        case .exponentialDelayed(let max, let initial, let multiplier):
            // if it's first attempt, simply use initial delay, otherwise calculate delay
            let delay = currentRepetition == 1 ? initial : initial * pow(1 + multiplier, Double(currentRepetition - 1))
            return (maxCount: max, delay: .milliseconds(Int(delay * 1000)))
        case .customTimerDelayed(let max, let delayCalculator):
            // calculate delay using provided calculator
            return (maxCount: max, delay: delayCalculator(currentRepetition))
        }
    }
}

public typealias RetryPredicate = (Error) -> Bool

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
    /**
     Repeats the source observable sequence using given behavior in case of an error or until it successfully terminated
     - parameter behavior: Behavior that will be used in case of an error
     - parameter scheduler: Schedular that will be used for delaying subscription after error
     - parameter shouldRetry: Custom optional closure for checking error (if returns true, repeat will be performed)
     - returns: Observable sequence that will be automatically repeat if error occurred
     */

    public func retry<Context>(_ behavior: RepeatBehavior<Context>, scheduler: Context, shouldRetry: RetryPredicate? = nil) -> AnyPublisher<Output, Failure> where Context: Scheduler {
        return retry(1, behavior: behavior, scheduler: scheduler, shouldRetry: shouldRetry)
    }

    /**
     Repeats the source observable sequence using given behavior in case of an error or until it successfully terminated
     - parameter currentAttempt: Number of current attempt
     - parameter behavior: Behavior that will be used in case of an error
     - parameter scheduler: Schedular that will be used for delaying subscription after error
     - parameter shouldRetry: Custom optional closure for checking error (if returns true, repeat will be performed)
     - returns: Observable sequence that will be automatically repeat if error occurred
     */
    internal func retry<Context>(
        _ currentAttempt: UInt,
        behavior: RepeatBehavior<Context>,
        scheduler: Context,
        shouldRetry: RetryPredicate? = nil)
    -> AnyPublisher<Output, Failure> where Context: Scheduler {
        guard currentAttempt > 0 else { return Empty().eraseToAnyPublisher() }

        // calculate conditions for bahavior
        let conditions = behavior.calculateConditions(currentAttempt)
        
        return self.catch { error -> AnyPublisher<Output, Failure> in

            // return error if exceeds maximum amount of retries
            guard conditions.maxCount > currentAttempt else {
                return Fail(error: error).eraseToAnyPublisher()
            }

            if let shouldRetry = shouldRetry, !shouldRetry(error) {
                // also return error if predicate says so
                return  Fail(error: error).eraseToAnyPublisher()
            }

            guard conditions.delay != .zero else {
                // if there is no delay, simply retry
                return self.retry(currentAttempt + 1, behavior: behavior, scheduler: scheduler, shouldRetry: shouldRetry)
                    .eraseToAnyPublisher()
            }

            // otherwise retry after specified delay
            return Just(()).setFailureType(to: Failure.self)
                .delay(for: conditions.delay, tolerance: nil, scheduler: scheduler, options: nil)
                .flatMap { _ -> AnyPublisher<Output, Failure> in
                    self.retry(currentAttempt + 1, behavior: behavior, scheduler: scheduler, shouldRetry: shouldRetry)
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

#endif
