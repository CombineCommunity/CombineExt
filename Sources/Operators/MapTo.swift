//
//  MapTo.swift
//  CombineExt
//
//  Created by Dan Halliday on 08/05/2022.
//  Copyright © 2022 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// Replace each upstream value with a constant.
    ///
    /// - Parameter value: The constant with which to replace each upstream value.
    /// - Returns: A new publisher wrapping the upstream, but with output type `Result`.
    func map<Result>(to value: Result) -> Publishers.Map<Self, Result> {
        map { _ in value }
    }
}

#endif
