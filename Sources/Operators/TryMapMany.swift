//
//  TryMapMany.swift
//  CombineExt
//
//  Created by Joan Disho on 07/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

public extension Publisher where Output: Collection {
    /// Projects each element of a publisher collection into a new publisher collection form.
    ///
    /// - parameter transform: An error-throwing transformation function which applies to each element of the source collection.
    ///  If `transform` throws an error, the publisher fails with the thrown error.
    ///
    ///
    /// - returns: A publisher collection whose elements are the result of invoking the transformation function on each element of the source.
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    let intArrayPublisher = PassthroughSubject<[Int], Never>()
    ///
    ///    intArrayPublisher
    ///         .tryMapMany(String.init)
    ///         .sink(receiveValue: { print($0) })
    ///
    ///    intArrayPublisher.send([10, 2, 2, 4, 3, 8])
    ///
    ///    // Output: ["10", "2", "2", "4", "3", "8"]
    ///    ```
    ///
    /// In case of an error:
    ///
    ///     let intArrayPublisher = PassthroughSubject<[Int], NumberError>()
    ///
    ///     intArrayPublisher
    ///         .tryMapMany { number in
    ///             if number < 5 {
    ///                throw NumberError.numberSmallerThanFive
    ///             }
    ///             return "\(number)"
    ///         }
    ///         .sink(receiveValue: { print($0) })
    ///
    ///     intArrayPublisher.send([10, 2, 2, 4, 3, 8])
    ///
    ///     // Output: []
    ///     // Error: NumberError.numberSmallerThanFive

    func tryMapMany<Result>(_ transform: @escaping (Output.Element) throws -> Result) -> Publishers.TryMap<Self, [Result]> {
        tryMap { try $0.map(transform) }
    }
}
