//
//  FilterMany.swift
//  CombineExt
//
//  Created by Hugo Saynac on 29/09/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Output: Collection {
    /// Filters element of a publisher collection into a new publisher collection.
    ///
    /// - parameter isIncluded: A filter function which applies to each element of the source collection.
    ///
    /// - returns: A publisher collection whose elements are included by the filter  function on each element of the source.
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    let intArrayPublisher = PassthroughSubject<[Int], Never>()
    ///
    ///    intArrayPublisher
    ///         .filterMany { $0.isMultiple(of: 2) }
    ///         .sink(receiveValue: { print($0) })
    ///
    ///    intArrayPublisher.send([10, 1, 2, 4, 3, 8])
    ///
    ///    // Output: [10, 1, 2, 4, 8]
    ///    ```
    ///
    ///
    func filterMany(_ isIncluded: @escaping (Output.Element) -> Bool) -> AnyPublisher<[Output.Element], Failure> {
        map { $0.filter(isIncluded) }
            .eraseToAnyPublisher()
    }
}
#endif
