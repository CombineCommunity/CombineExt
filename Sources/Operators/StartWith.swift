//
//  StartWith.swift
//  CombineExt
//
//  Created by Sergey Pugach on 10/7/20.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    func startWith(_ value: Self.Output) -> Publishers.Merge<AnyPublisher<Self.Output, Self.Failure>, Self> {
        return Publishers.Merge(
            Just(value)
                .setFailureType(to: Self.Failure.self)
                .eraseToAnyPublisher(),
            self
        )
    }
}
#endif
