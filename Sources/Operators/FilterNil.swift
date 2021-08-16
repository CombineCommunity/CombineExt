//
//  FilterNil.swift
//  CombineExt
//
//  Created by Andrew Breckenridge on 8/16/21.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Output: OptionalType {
    /// Filters nil elements from a publisher
    ///
    /// - returns: A publisher collection whose elements are non nil.
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    let sometimesNilPublisher = PassthroughSubject<Int?, Never>()
    ///
    ///    sometimesNilPublisher
    ///         .filterNil()
    ///         .sink(receiveValue: { print($0) })
    ///
    ///    sometimesNilPublisher.send([nil, 1, 2, nil, nil, 8, nil])
    ///
    ///    // Output:
    ///    // 1
    ///    // 2
    ///    // 8
    ///    ```
    ///
    func filterNil() -> Publishers.FlatMap<AnyPublisher<Self.Output.Wrapped, Self.Failure>, Self> {
        return flatMap { optional -> AnyPublisher<Output.Wrapped, Failure> in
            switch optional.value {
            case .none:
                return Empty<Output.Wrapped, Failure>()
                    .eraseToAnyPublisher()
            case .some(let wrapped):
                return Just<Output.Wrapped>(wrapped)
                    .setFailureType(to: Failure.self)
                    .eraseToAnyPublisher()
            }
        }
    }
}

/// A type wrapper for `Optional` to allow protocol specializations for `Optional` values
public protocol OptionalType {
    associatedtype Wrapped

    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    public var value: Wrapped? {
        return self
    }
}
#endif
