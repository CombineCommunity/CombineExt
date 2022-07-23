//
//  PrefixWhileBehavior.swift
//  CombineExt
//
//  Created by Jasdev Singh on 29/12/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine
import Foundation

/// Whether to include the first element that doesn’t pass
/// the `while` predicate passed to `Combine.Publisher.prefix(while:behavior:)`.
public enum PrefixWhileBehavior {
    /// Include the first element that doesn’t pass the `while` predicate.
    case inclusive

    /// Exclude the first element that doesn’t pass the `while` predicate.
    case exclusive
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// An overload on `Publisher.prefix(while:)` that allows for inclusion of the first element that doesn’t pass the `while` predicate.
    ///
    /// - parameters:
    ///   - predicate: A closure that takes an element as its parameter and returns a Boolean value that indicates whether publishing should continue.
    ///   - behavior: Whether or not to include the first element that doesn’t pass `predicate`.
    ///
    /// - returns: A publisher that passes through elements until the predicate indicates publishing should finish — and optionally that first `predicate`-failing element.
    func prefix(
        while predicate: @escaping (Output) -> Bool,
        behavior: PrefixWhileBehavior = .exclusive
    ) -> AnyPublisher<Output, Failure> {
        switch behavior {
        case .exclusive:
            return prefix(while: predicate)
                .eraseToAnyPublisher()
        case .inclusive:
            return flatMap { next in
                Just(PrefixInclusiveEvent.whileValueOrIncluded(next))
                    .append(!predicate(next) ? [.end] : [])
                    .setFailureType(to: Failure.self)
            }
            .prefix(while: \.isWhileValueOrIncluded)
            .compactMap(\.value)
            .eraseToAnyPublisher()
        }
    }
}
#endif

// MARK: - Helpers

private enum PrefixInclusiveEvent<Output> {
    case end
    case whileValueOrIncluded(Output)

    var isWhileValueOrIncluded: Bool {
        switch self {
        case .end:
            return false
        case .whileValueOrIncluded:
            return true
        }
    }

    var value: Output? {
        switch self {
        case .end:
            return nil
        case let .whileValueOrIncluded(inner):
            return inner
        }
    }
}
