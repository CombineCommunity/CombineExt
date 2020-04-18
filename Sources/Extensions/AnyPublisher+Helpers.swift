//
//  AnyPublisher.swift
//  CombineExt
//
//  Created by Prince Ugwuh on 3/30/20.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

public extension AnyPublisher {
    /**
    Returns an empty publisher.
    - returns: An publisher with no elements.
    */
    static func empty(completeImmediately: Bool = true) -> AnyPublisher<Output, Failure> {
        return Empty(completeImmediately: completeImmediately).eraseToAnyPublisher()
    }

    /**
    Returns a publisher with an `error`.
    - returns: The publisher with specified error.
    */
    static func fail(_ failure: Failure) -> AnyPublisher<Output, Failure> {
        return Fail(error: failure).eraseToAnyPublisher()
    }

    /**
    Returns a publisher with an `error`.
    - parameter outputType: Output type
    - parameter failure: Failure error
    - returns: The publisher with specified error.
    */
    static func fail(outputType: Output.Type, failure: Failure) -> AnyPublisher<Output, Failure> {
        return Fail(error: failure).eraseToAnyPublisher()
    }

    /**
    Returns a publisher that contains a single element.
    
    - parameter element: Single element in the resulting publisher.
    - returns: A publisher containing the single specified element, Never as a Failure
    */
    static func just(_ output: Output) -> AnyPublisher<Output, Never> {
        return Just(output).eraseToAnyPublisher()
    }

    /**
    Returns a non-terminating observable sequence, which can be used to denote an infinite duration.
    - returns: A publisher whose observers will never get called.
    */
    static func never() -> AnyPublisher<Never, Failure> {
        return Never.NeverPublisher().eraseToAnyPublisher()
    }

    /**
        Returns a publisher that waits for a subscriber before running the provided closure to create values for the subscriber.
        - parameter createPublisher: Creates a publisher that invokes a promise closure when the publisher emits an element.
        - returns: When triggered a new publisher
        */
    static func deferred<P: Publisher>(_ createPublisher: @escaping () -> P) -> AnyPublisher<P.Output, P.Failure> {
        return Deferred(createPublisher: createPublisher).eraseToAnyPublisher()
    }

    /**
    Returns a publisher that eventually produces a single value and then finishes or fails.
    - parameter attemptToFulfill: Observable factory function to invoke for each observer that subscribes to the resulting sequence.
    - returns: A publisher with a closure that eventually resolves to a single output value or failure completion
    */
    static func future(_ attemptToFulfill: @escaping (@escaping Future<Output, Failure>.Promise) -> Void) -> AnyPublisher<Output, Failure> {
        return Future(attemptToFulfill).eraseToAnyPublisher()
    }

    /**
    Returns Result as a publisher.
    - parameter success: success value
    - returns: Returns Result sucess
    */
    static func result(_ success: Output) -> AnyPublisher<Output, Failure> {
        return Result<Output, Failure>.Publisher(success).eraseToAnyPublisher()
    }

    /**
    Returns Result as a publisher.
    - parameter failure: failure value
    - returns: Returns Result failure.
    */
    static func result(_ failure: Failure) -> AnyPublisher<Output, Failure> {
        return Result<Output, Failure>.Publisher(failure).eraseToAnyPublisher()
    }
}

public extension AnyPublisher {
    /**
    Continues a publisher that is terminated by an error with a fallback output.
    - parameter output: default value in case error occurs.
    - returns: An observable sequence containing the source sequence's elements, followed by the `element` in case an error occurred.
    */
    func catchErrorJustReturn(_ output: Output) -> AnyPublisher<Output, Never> {
        return self.catch { _ in AnyPublisher.just(output) }.eraseToAnyPublisher()
    }
}

fileprivate extension Never {
    struct NeverPublisher<Output, Failure: Error>: Publisher {
        func receive<S: Subscriber>(subscriber: S) {}
    }
}
