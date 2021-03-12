//
//  LiftErrorFromResult.swift
//  CombineExt
//
//  Created by Yurii Zadoianchuk on 12/03/2021.
//  Copyright © 2021 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Self.Failure == Never {
    /// Transform a never-failing publisher with Result<T, E> as output
    /// to a new publisher that unwraps Result and sets T as Output and E as Failure
    /// - Returns: a type-erased publisher of type <T, E>
    func liftErrorFromResult<T, E>() -> AnyPublisher<T, E>
    where Output == Result<T, E> {
        setFailureType(to: E.self)
            .flatMap { (result: Result<T, E>) -> AnyPublisher<T, E> in
                switch result {
                case .success(let some):
                    return Just(some)
                        .setFailureType(to: E.self)
                        .eraseToAnyPublisher()
                case .failure(let error):
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }.eraseToAnyPublisher()
    }
}

#endif
