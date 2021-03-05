//
//  CatchToResult.swift
//  CombineExt
//
//  Created by Yurii Zadoianchuk on 05/03/2021.
//  Copyright © 2021 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Failure: Error {
    /// Transform a publisher with concrete Output and Failure types
    /// to a new publisher that wraps Output and Failure in Result,
    /// and has Never for Failure type
    /// - Returns: A type-erased publiser of type <Result<Output, Failure>, Never>
    func catchToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        self.map({ Result.success($0) })
            .catch({ Just(.failure($0)) })
            .eraseToAnyPublisher()
    }
}

#endif
