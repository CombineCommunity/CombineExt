//
//  WeakAssign.swift
//  CombineExt
//
//  Created by Apostolos Giokas on 07/06/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Self.Failure == Never {
    /// Assigns each element from a Publisher to a property on an object.
    /// The `object` will not be retained.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the property to assign.
    ///   - object: The object on which to assign the value.
    /// - Returns: A cancellable instance; used when you end assignment of the received value.
    ///  Deallocation of the object will tear down the subscription stream.
    func weakAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>,
                                     on object: Root) -> AnyCancellable {
        let subscriber = WeakAssign(object: object, keyPath: keyPath)
        subscribe(subscriber)
        return AnyCancellable(subscriber)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class WeakAssign<Root: AnyObject, Input>: Subscriber, Cancellable {
    private(set) weak var object: Root?

    let keyPath: ReferenceWritableKeyPath<Root, Input>

    private var status = SubscriptionStatus.awaiting

    init(object: Root, keyPath: ReferenceWritableKeyPath<Root, Input>) {
        self.object = object
        self.keyPath = keyPath
    }

    func receive(subscription: Subscription) {
        switch status {
        case .awaiting:
            status = .subscribed(subscription)
            subscription.request(.unlimited)
        case .subscribed, .terminated:
            subscription.cancel()
        }
    }

    func receive(_ value: Input) -> Subscribers.Demand {
        switch status {
        case .subscribed:
            object?[keyPath: keyPath] = value
        case .awaiting, .terminated:
            break
        }
        return .none
    }

    func receive(completion _: Subscribers.Completion<Never>) { cancel() }

    func cancel() {
        guard case let .subscribed(subscription) = status else {
            return
        }
        subscription.cancel()
        status = .terminated
        object = nil
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private enum SubscriptionStatus {
    case awaiting
    case subscribed(Subscription)
    case terminated
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension WeakAssign: CustomStringConvertible {
    public var description: String { return "Assign \(Root.self)." }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension WeakAssign: CustomPlaygroundDisplayConvertible {
    public var playgroundDescription: Any { description }
}
