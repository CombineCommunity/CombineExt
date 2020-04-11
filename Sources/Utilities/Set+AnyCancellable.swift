//
//  Set+AnyCancellable.swift
//  CombineExt
//
//  Created by Jasdev Singh on 10/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

public extension Set where Element == AnyCancellable {
    /// Convenience storage method on `Set` for a veridic number of `AnyCancellable`s.
    ///
    /// `Set.store(_:)` can save repeated [AnyCancellable.store(in:)](https://developer.apple.com/documentation/combine/anycancellable/3333294-store) calls, e.g.
    ///
    /// ```
    /// firstPublisher
    ///     .sink( /* … */ )
    ///     .store(in: &subscriptions)
    ///
    /// secondPublisher
    ///     .sink( /* … */ )
    ///     .store(in: &subscriptions)
    ///
    /// thirdPublisher
    ///     .sink( /* … */ )
    ///     .store(in: &subscriptions)
    /// ```
    ///
    /// can be rewritten as
    ///
    /// ```
    /// subscriptions.store(
    ///     firstPublisher
    ///         .sink( /* … */ ),
    ///     secondPublisher
    ///         .sink( /* … */ ),
    ///     thirdPublisher
    ///         .sink( /* … */ )
    /// )
    /// ```
    ///
    /// - parameter cancellables: The cancellables to store in the `Set`.
    mutating func store(_ cancellables: AnyCancellable...) {
        store(cancellables)
    }

    /// Convenience storage method on `Set` for a `Sequence` of `AnyCancellable`s.
    ///
    /// `Set.store(_:)` can help in situations where you want to store batches of cancellables in one go, e.g.
    ///
    /// ```
    /// let firstBatchOfCancellables = […]
    ///
    /// /* … */
    ///
    /// let secondBatchOfCancellables = […]
    ///
    /// /* … */
    ///
    /// let thirdBatchOfCancellables = […]
    ///
    /// subscriptions.store(
    ///     firstBatchOfCancellables +
    ///     secondBatchOfCancellables +
    ///     thirdBatchOfCancellables
    /// )
    /// ```
    ///
    /// - parameter cancellables: The cancellables to store in the `Set`.
    mutating func store<Sequence: Swift.Sequence>(_ cancellables: Sequence) where Sequence.Element == AnyCancellable {
        cancellables.forEach { insert($0) }
    }
}
