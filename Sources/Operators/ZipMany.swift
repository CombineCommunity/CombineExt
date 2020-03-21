//
//  ZipMany.swift
//  CombineExt
//
//  Created by Jasdev Singh on 16/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

public extension Publisher {
    // MARK: - Non-transform zipping variants.

    /// Zips `self` with an array’s-worth of publishers with the same output and failure types.
    /// Since there can be any number of `others`, `[Output]` values are emitted after zipping.
    /// - Parameter others: The other publishers to zip with.
    ///
    /// - returns: A type-erased publisher with value events from each of the inner publishers zipped together in an array.
    func zip<Other: Publisher>(with others: [Other])
        -> AnyPublisher<[Output], Failure> where Other.Output == Output, Other.Failure == Failure {
        let seed = map { [$0] }.eraseToAnyPublisher()

        return others
            .reduce(seed) { zipped, next in
                zipped
                    .zip(next)
                    .map { $0.0 + [$0.1] }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// A variadic overload on `Publisher.zip(with:)`.
    func zip<Other: Publisher>(with others: Other...)
        -> AnyPublisher<[Output], Failure> where Other.Output == Output, Other.Failure == Failure {
            zip(with: others)
    }

    // MARK: - Transform zipping variants.

    /// A overload on `Publisher.zip(with:)` that tacks on the option to transform the zipped `[Output]` values
    /// into another generic, `Transformed`.
    func zip<Other: Publisher, Transformed>(with others: [Other], transform: @escaping ([Output]) -> Transformed)
        -> Publishers.Map<AnyPublisher<[Output], Failure>, Transformed>
        where Other.Output == Output, Other.Failure == Failure {
            zip(with: others).map(transform)
    }

    /// A variadic overload on `Publisher.zip(with:transform)`.
    func zip<Other: Publisher, Transformed>(with others: Other..., transform: @escaping ([Output]) -> Transformed)
        -> Publishers.Map<AnyPublisher<[Output], Failure>, Transformed>
        where Other.Output == Output, Other.Failure == Failure {
            zip(with: others).map(transform)
    }
}
