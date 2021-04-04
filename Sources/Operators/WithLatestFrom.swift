//
//  WithLatestFrom.swift
//  CombineExt
//
//  Created by Shai Mishali on 29/08/2019.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

// MARK: - Operator methods
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    ///  Merges two publishers into a single publisher by combining each value
    ///  from self with the latest value from the second publisher, if any.
    ///
    ///  - parameter other: A second publisher source.
    ///  - parameter resultSelector: Function to invoke for each value from the self combined
    ///                              with the latest value from the second source, if any.
    ///
    ///  - returns: A publisher containing the result of combining each value of the self
    ///             with the latest value from the second publisher, if any, using the
    ///             specified result selector function.
    func withLatestFrom<Other: Publisher, Result>(_ other: Other,
                                                  resultSelector: @escaping (Output, Other.Output) -> Result)
    -> AnyPublisher<Result, Failure>
    where Other.Failure == Failure {
        let upstream = share()

        return other
            .map { second in upstream.map { resultSelector($0, second) } }
            .switchToLatest()
            .zip(upstream) // `zip`ping and discarding `\.1` allows for
            // upstream completions to be projected down immediately.
            .map(\.0)
            .eraseToAnyPublisher()
    }

    ///  Merges three publishers into a single publisher by combining each value
    ///  from self with the latest value from the second and third publisher, if any.
    ///
    ///  - parameter other: A second publisher source.
    ///  - parameter other1: A third publisher source.
    ///  - parameter resultSelector: Function to invoke for each value from the self combined
    ///                              with the latest value from the second and third source, if any.
    ///
    ///  - returns: A publisher containing the result of combining each value of the self
    ///             with the latest value from the second and third publisher, if any, using the
    ///             specified result selector function.
    func withLatestFrom<Other: Publisher, Other1: Publisher, Result>(_ other: Other,
                                                                     _ other1: Other1,
                                                                     resultSelector: @escaping (Output, (Other.Output, Other1.Output)) -> Result)
    -> AnyPublisher<Result, Failure>
    where Other.Failure == Failure, Other1.Failure == Failure {
        withLatestFrom(other.combineLatest(other1), resultSelector: resultSelector)
    }

    ///  Merges four publishers into a single publisher by combining each value
    ///  from self with the latest value from the second, third and fourth publisher, if any.
    ///
    ///  - parameter other: A second publisher source.
    ///  - parameter other1: A third publisher source.
    ///  - parameter other2: A fourth publisher source.
    ///  - parameter resultSelector: Function to invoke for each value from the self combined
    ///                              with the latest value from the second, third and fourth source, if any.
    ///
    ///  - returns: A publisher containing the result of combining each value of the self
    ///             with the latest value from the second, third and fourth publisher, if any, using the
    ///             specified result selector function.
    func withLatestFrom<Other: Publisher, Other1: Publisher, Other2: Publisher, Result>(_ other: Other,
                                                                                        _ other1: Other1,
                                                                                        _ other2: Other2,
                                                                                        resultSelector: @escaping (Output, (Other.Output, Other1.Output, Other2.Output)) -> Result)
    -> AnyPublisher<Result, Failure>
    where Other.Failure == Failure, Other1.Failure == Failure, Other2.Failure == Failure {
        withLatestFrom(other.combineLatest(other1, other2), resultSelector: resultSelector)
    }

    ///  Upon an emission from self, emit the latest value from the
    ///  second publisher, if any exists.
    ///
    ///  - parameter other: A second publisher source.
    ///
    ///  - returns: A publisher containing the latest value from the second publisher, if any.
    func withLatestFrom<Other: Publisher>(_ other: Other)
    -> AnyPublisher<Other.Output, Failure>
    where Other.Failure == Failure {
        withLatestFrom(other) { $1 }
    }

    /// Upon an emission from self, emit the latest value from the
    /// second and third publisher, if any exists.
    ///
    /// - parameter other: A second publisher source.
    /// - parameter other1: A third publisher source.
    ///
    /// - returns: A publisher containing the latest value from the second and third publisher, if any.
    func withLatestFrom<Other: Publisher, Other1: Publisher>(_ other: Other,
                                                             _ other1: Other1)
    -> AnyPublisher<(Other.Output, Other1.Output), Failure>
    where Other.Failure == Failure, Other1.Failure == Failure {
        withLatestFrom(other, other1) { $1 }
    }

    /// Upon an emission from self, emit the latest value from the
    /// second, third and forth publisher, if any exists.
    ///
    /// - parameter other: A second publisher source.
    /// - parameter other1: A third publisher source.
    /// - parameter other2: A forth publisher source.
    ///
    /// - returns: A publisher containing the latest value from the second, third and forth publisher, if any.
    func withLatestFrom<Other: Publisher, Other1: Publisher, Other2: Publisher>(_ other: Other,
                                                                                _ other1: Other1,
                                                                                _ other2: Other2)
    -> AnyPublisher<(Other.Output, Other1.Output, Other2.Output), Failure>
    where Other.Failure == Failure, Other1.Failure == Failure, Other2.Failure == Failure {
        withLatestFrom(other, other1, other2) { $1 }
    }
}
#endif
