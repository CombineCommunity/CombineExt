//
//  FlatMapSource.swift
//  CombineExt
//
//  Created by Thibault Wittemberg on 19/10/2020.
//  Copyright © 2020 Combine Community. All rights reserved.

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher{
    /// Same as flatMap, but uses the output from the Upstream to form a tuple with the output from the Downstream.
    ///
    /// - parameter transform: A transform to apply to each emitted value
    ///
    /// - returns: A publisher which output is a tuple of output from both Upstream and Downstream
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    let upStream = api.fetchCallA()
    ///
    ///    upStream
    ///         .flatMapSource { outputA in return api.fetchCallB(with: outputA) }
    ///         .sink(receiveValue: { print($0) })
    ///
    ///    // Output: (outputA, outputB)
    ///    ```
    ///
    ///
    func flatMapSource<Downstream: Publisher>(
        _ transform: @escaping (Output) -> Downstream
    ) -> AnyPublisher<(Output, Downstream.Output), Downstream.Failure> where Downstream.Failure == Failure {
        self.flatMap { output in transform(output).map { (output, $0) } }.eraseToAnyPublisher()
    }
}
#endif
