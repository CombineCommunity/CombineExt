//
//  Unwrap.swift
//  CombineExt
//
//  Created by Sergey Pugach on 10/7/20.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    func unwrap() -> Publishers.CompactMap<Self, Self.Output> {
        return compactMap({ $0 })
    }
}
#endif

