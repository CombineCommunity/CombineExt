//
//  SetOutputType.swift
//  CombineExt
//
//  Created by Jasdev Singh on 02/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

public extension Publisher where Output == Never {
    /// An output analog to [Publisher.setFailureType(to:)](https://developer.apple.com/documentation/combine/publisher/3204753-setfailuretype) for when `Output == Never`. The is especially helpful when chained after [.ignoreOutput()](https://developer.apple.com/documentation/combine/publisher/3204714-ignoreoutput) operator calls.
    ///
    /// - Parameter outputType: The new output type for downstream.
    ///
    /// - Returns: A publisher with a `NewOutput` output type.
    func setOutputType<NewOutput>(to outputType: NewOutput.Type) -> Publishers.Map<Self, NewOutput> {
        map { _ -> NewOutput in }
    }
}
