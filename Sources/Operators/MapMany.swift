//
//  MapMany.swift
//  CombineExt
//
//  Created by Joan Disho on 22/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

public extension Publisher where Output: Collection {
    /// Projects each element of a publisher collection into a new publisher collection form.
    ///
    /// - parameter transform: A transformation function which applies to each element of the source collection.
    ///
    /// - returns: A publisher collection whose elements are the result of invoking the transformation function on each element of the source.
    ///
    /// An example usage could look as follows:
        ///
        ///    ```
        ///    let intArrayPublisher = PassthroughSubject<[Int], Never>()
        ///
        ///    intArrayPublisher
        ///         .mapMany(String.init)
        ///         .sink(receiveValue: { print($0) })
        ///
        ///    intArrayPublisher.send([10, 2, 2, 4, 3, 8])
        ///
        ///    // Output: ["10", "2", "2", "4", "3", "8"]
        ///    ```
        ///
    ///
    func mapMany<T>(_ transform: @escaping (Output.Element) -> T) -> Publishers.Map<Self, [T]> {
        return map { $0.map(transform) }
    }
}
