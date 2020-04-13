//
//  ShareReplay.swift
//  CombineExt
//
//  Created by Jasdev Singh on 13/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

public extension Publisher {
    /// An overload on [Publisher.share](https://developer.apple.com/documentation/combine/publisher/3204754-share)
    /// that allows for buffering and replaying a `replay` amount of value events to future subscribers.
    /// - Parameter count: The number of value events to buffer in a [first-in-first-out](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics)) manner.
    /// - Returns: A type-erased, shared publisher that replays the specified number of value events to future subscribers.
    func share(replay count: UInt) -> AnyPublisher<Output, Failure> {
        multicast { ReplaySubject(maxBufferSize: count) }
            .autoconnect()
            .eraseToAnyPublisher()
    }
}
