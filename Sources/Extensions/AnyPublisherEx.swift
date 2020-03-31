//
//  AnyPublisher.swift
//  CombineExt
//
//  Created by Prince Ugwuh on 3/30/20.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

public extension AnyPublisher {
    static func empty(completeImmediately: Bool = true) -> AnyPublisher<Output, Failure> {
        return Empty(completeImmediately: completeImmediately).eraseToAnyPublisher()
    }

    static func fail(_ failure: Failure) -> AnyPublisher<Output, Failure> {
        return Fail(error: failure).eraseToAnyPublisher()
    }

    static func fail(outputType: Output.Type, failure: Failure) -> AnyPublisher<Output, Failure> {
        return Fail(error: failure).eraseToAnyPublisher()
    }

    static func just(_ output: Output) -> AnyPublisher<Output, Never> {
        return Just(output).eraseToAnyPublisher()
    }

    static func deferred<P: Publisher>(_ createPublisher: @escaping () -> P) -> AnyPublisher<P.Output, P.Failure> {
        return Deferred(createPublisher: createPublisher).eraseToAnyPublisher()
    }

    static func future(_ attemptToFulfill: @escaping (@escaping Future<Output, Failure>.Promise) -> Void) -> AnyPublisher<Output, Failure> {
        return Future(attemptToFulfill).eraseToAnyPublisher()
    }
}
