//
//  AssignOwnership.swift
//  CombineExt
//
//  Created by Dmitry Kuznetsov on 08/05/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Self.Failure == Never {
    /// Assigns a publisher’s output to a property of an object.
    ///
    /// - parameter keyPath: A key path that indicates the property to assign.
    /// - parameter object: The object that contains the property.
    ///                     The subscriber assigns the object’s property every time
    ///                     it receives a new value.
    /// - parameter ownership: The retainment / ownership strategy for the object, defaults to `strong`.
    ///
    /// - returns: An AnyCancellable instance. Call cancel() on this instance when you no longer want
    ///            the publisher to automatically assign the property. Deinitializing this instance
    ///            will also cancel automatic assignment.
    func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>,
                                 on object: Root,
                                 ownership: ObjectOwnership = .strong) -> AnyCancellable {
        switch ownership {
        case .strong:
            return assign(to: keyPath, on: object)
        case .weak:
            return sink { [weak object] value in
                object?[keyPath: keyPath] = value
            }
        case .unowned:
            return sink { [unowned object] value in
                object[keyPath: keyPath] = value
            }
        }
    }

    /// Assigns each element from a Publisher to properties of the provided objects
    ///
    /// - Parameters:
    ///   - keyPath1: The key path of the first property to assign.
    ///   - object1: The first object on which to assign the value.
    ///   - keyPath2: The key path of the second property to assign.
    ///   - object2: The second object on which to assign the value.
    ///   - ownership: The retainment / ownership strategy for the object, defaults to `strong`.
    ///
    /// - Returns: A cancellable instance; used when you end assignment of the received value.
    ///            Deallocation of the result will tear down the subscription stream.
    func assign<Root1: AnyObject, Root2: AnyObject>(
        to keyPath1: ReferenceWritableKeyPath<Root1, Output>, on object1: Root1,
        and keyPath2: ReferenceWritableKeyPath<Root2, Output>, on object2: Root2,
        ownership: ObjectOwnership = .strong
    ) -> AnyCancellable {
        switch ownership {
        case .strong:
            return assign(to: keyPath1, on: object1, and: keyPath2, on: object2)
        case .weak:
            return sink { [weak object1, weak object2] value in
                object1?[keyPath: keyPath1] = value
                object2?[keyPath: keyPath2] = value
            }
        case .unowned:
            return sink { [unowned object1, unowned object2] value in
                object1[keyPath: keyPath1] = value
                object2[keyPath: keyPath2] = value
            }
        }
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
    ///   - ownership: The retainment / ownership strategy for the object, defaults to `strong`.
    ///
    /// - Returns: A cancellable instance; used when you end assignment of the received value.
    ///            Deallocation of the result will tear down the subscription stream.
    func assign<Root1: AnyObject, Root2: AnyObject, Root3: AnyObject>(
        to keyPath1: ReferenceWritableKeyPath<Root1, Output>, on object1: Root1,
        and keyPath2: ReferenceWritableKeyPath<Root2, Output>, on object2: Root2,
        and keyPath3: ReferenceWritableKeyPath<Root3, Output>, on object3: Root3,
        ownership: ObjectOwnership = .strong
    ) -> AnyCancellable {
        switch ownership {
        case .strong:
            return assign(to: keyPath1, on: object1,
                          and: keyPath2, on: object2,
                          and: keyPath3, on: object3)
        case .weak:
            return sink { [weak object1, weak object2, weak object3] value in
                object1?[keyPath: keyPath1] = value
                object2?[keyPath: keyPath2] = value
                object3?[keyPath: keyPath3] = value
            }
        case .unowned:
            return sink { [unowned object1, unowned object2, unowned object3] value in
                object1[keyPath: keyPath1] = value
                object2[keyPath: keyPath2] = value
                object3[keyPath: keyPath3] = value
            }
        }
    }
}
#endif
