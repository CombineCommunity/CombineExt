//
//  IgnoreOutputSetOutputType.swift
//  CombineExt
//
//  Created by Jasdev Singh on 02/09/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// An `ignoreOutput` overload that allows for setting a new output type.
    ///
    /// - parameter setOutputType: The new output type for downstream.
    ///
    /// - returns: A publisher that ignores upstream value events and sets its output generic to `NewOutput`.
    func ignoreOutput<NewOutput>(setOutputType newOutputType: NewOutput.Type) -> Publishers.Map<Publishers.IgnoreOutput<Self>, NewOutput> {
        ignoreOutput().map { _ -> NewOutput in }
    }
}
#endif
