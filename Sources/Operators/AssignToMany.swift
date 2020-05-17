//
//  AssignToMany.swift
//  CombineExt
//
//  Created by Shai Mishali on 13/02/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Self.Failure == Never {
    /// Assigns each element from a Publisher to properties of the provided objects
    ///
    /// - Parameters:
    ///   - keyPath1: The key path of the first property to assign.
    ///   - object1: The first object on which to assign the value.
    ///   - keyPath2: The key path of the second property to assign.
    ///   - object2: The second object on which to assign the value.
    ///
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    func assign<Root1, Root2>(to keyPath1: ReferenceWritableKeyPath<Root1, Output>, on object1: Root1,
                              and keyPath2: ReferenceWritableKeyPath<Root2, Output>, on object2: Root2) -> AnyCancellable {
        sink(receiveValue: { value in
            object1[keyPath: keyPath1] = value
            object2[keyPath: keyPath2] = value
        })
    }

    /// Assigns each element from a Publisher to properties of the provided objects
    ///
    /// - Parameters:
    ///   - keyPath1: The key path of the first property to assign.
    ///   - object1: The first object on which to assign the value.
    ///   - keyPath2: The key path of the second property to assign.
    ///   - object2: The second object on which to assign the value.
    ///   - keyPath3: The key path of the third property to assign.
    ///   - object3: The third object on which to assign the value.
    ///
    /// - Returns: A cancellable instance; used when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    func assign<Root1, Root2, Root3>(to keyPath1: ReferenceWritableKeyPath<Root1, Output>, on object1: Root1,
                                     and keyPath2: ReferenceWritableKeyPath<Root2, Output>, on object2: Root2,
                                     and keyPath3: ReferenceWritableKeyPath<Root3, Output>, on object3: Root3) -> AnyCancellable {
        sink(receiveValue: { value in
            object1[keyPath: keyPath1] = value
            object2[keyPath: keyPath2] = value
            object3[keyPath: keyPath3] = value
        })
    }
}
#endif
