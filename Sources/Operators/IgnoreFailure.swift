//
//  IgnoreFailure.swift
//  CombineExt
//
//  Created by Jasdev Singh on 17/10/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// An analog to `ignoreOutput` for `Publisher`’s `Failure` generic, allowing for either no or an immediate completion on an error event.
    ///
    /// - parameter completeImmediately: Whether the returned publisher should complete on an error event. Defaults to `true`.
    ///
    /// - returns: A publisher that ignores upstream error events.
    func ignoreFailure(completeImmediately: Bool = true) -> AnyPublisher<Output, Never> {
        `catch` { _ in Empty(completeImmediately: completeImmediately) }
            .eraseToAnyPublisher()
    }

    /// An `ignoreFailure` overload that also allows for setting a new failure type.
    ///
    /// - parameter setFailureType: The failure type of the returned publisher.
    /// - parameter completeImmediately: Whether the returned publisher should complete on an error event. Defaults to `true`.
    ///
    /// - returns: A publisher that ignores upstream error events and has its `Failure` generic pinned to the specified failure type.
    func ignoreFailure<NewFailure: Error>(
        setFailureType newFailureType: NewFailure.Type,
        completeImmediately: Bool = true) -> AnyPublisher<Output, NewFailure> {
        ignoreFailure(completeImmediately: completeImmediately)
            .setFailureType(to: newFailureType)
            .eraseToAnyPublisher()
    }
}
#endif
