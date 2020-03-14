//
//  Event.swift
//  CombineExt
//
//  Created by Shai Mishali on 13/03/2020.
//  Copyright © 2019 Combine Community. All rights reserved.
//

/// Repressents a Combine Event
public enum Event<Output, Failure: Swift.Error> {
    case value(Output)
    case error(Failure)
    case finished
}
