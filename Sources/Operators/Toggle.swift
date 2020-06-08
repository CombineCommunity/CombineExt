//
//  Toggle.swift
//  CombineExt
//
//  Created by Keita Watanabe on 06/06/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Output == Bool {
    /// Toggles boolean values emitted by a publisher.
    ///
    /// - returns: A toggled value.
    func toggle() -> Publishers.Map<Self, Bool> {
        map(!)
    }
}
#endif
