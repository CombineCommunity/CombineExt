//
//  ZipMany.swift
//  CombineExt
//
//  Created by Jasdev Singh on 16/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

public extension Publisher {
    /// Zips `self` with an array of publishers with the same output and failure types.
    ///
    /// Since there can be any number of `others`, arrays of `Output` values are emitted after zipping.
    ///
    /// - parameter others: The other publishers to zip with.
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
}

// MARK: - Array Helpers
public extension Array where Element: Publisher {
    /// Zip an array of publishers with the same output and failure types.
    ///
    /// Since there can be any number of elements, arrays of `Output` values are emitted after zipping.
    ///
    /// - returns: A type-erased publisher with value events from each of the inner publishers zipped together in an array.
    func zip() -> AnyPublisher<[Element.Output], Element.Failure> {
        switch count {
        case 0:
            return Empty(completeImmediately: true).eraseToAnyPublisher()
        case 1:
            return self[0].map { [$0] }.eraseToAnyPublisher()
        default:
            let first = self[0]
            let others = Array(self[1...])
            return first.zip(with: others)
        }
    }
}
