//
//  Bind.swift
//  CombineExt
//
//  Created by Vitaly Banik on 17/08/2022.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    
    func bind<T: Subject>(to subject: T) -> AnyCancellable
    where T.Output == Output,
          T.Failure == Failure {
              
        self.sink { [weak subject] completion in
            subject?.send(completion: completion)
        } receiveValue: { [weak subject] value in
            subject?.send(value)
        }
    }
}
#endif
