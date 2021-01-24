//
//  BatchedSubscribe.swift
//  CombineExt
//
//  Created by Shai Mishali, Nate Cook, and Jasdev Singh on 21/01/2021.
//  Copyright © 2021 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Collection where Element: Publisher {
    /// Subscribes to the receiver’s contained publishers `limit` at a time
    /// and outputs their results in `limit`-sized batches, while maintaining
    /// order within each batch — subsequent batches of publishers are only
    /// subscribed to when the batch before it successfully completes. Any
    /// one failure will be forwarded downstream.
    /// - Parameter limit: The batch size.
    /// - Returns: A publisher that subscribes to `self`’s contained publishers
    /// `limit` at a time, returning their results in-order in `limit`-sized
    /// batches, and then repeats with subsequent batches only if the ones prior
    /// successfully completed. Any one failure is immediately forwarded downstream.
    func batchedSubscribe(by limit: Int) -> AnyPublisher<[Element.Output], Element.Failure> {
        precondition(limit > 0, "Batch sizes must be positive.")

        let indexBreaks = sequence(
            first: startIndex,
            next: {
                $0 == endIndex ?
                    nil :
                    index($0, offsetBy: limit, limitedBy: endIndex)
                        ?? endIndex
            }
        )

        return Swift.zip(indexBreaks, indexBreaks.dropFirst())
            .publisher
            .setFailureType(to: Element.Failure.self)
            .flatMap(maxPublishers: .max(1)) { self[$0..<$1].zip() }
            .eraseToAnyPublisher()
    }
}
#endif
