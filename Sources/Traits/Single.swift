//
//  Single.swift
//  CombineExt
//
//  Created by Shai Mishali on 17/05/2020.
//

#if canImport(Combine)
import Combine

public struct Single<Output, Failure: Swift.Error>: Publisher {
    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
    }

    init(factory: @escaping (Result<Output, Failure>) -> () -> AnyCancellable) {
        
    }
}
#endif
