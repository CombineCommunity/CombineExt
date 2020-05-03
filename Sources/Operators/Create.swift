//
//  Create.swift
//  CombineExt
//
//  Created by Shai Mishali on 13/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine
import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AnyPublisher {
    /// Create a publisher which accepts a closure with a subscriber argument,
    /// to which you can dynamically send value or completion events.
    ///
    /// You should return a `Cancelable`-conforming object from the closure in
    /// which you can define any cleanup actions to execute when the pubilsher
    /// completes or the subscription to the publisher is canceled.
    ///
    /// - parameter factory: A factory with a closure to which you can
    ///                      dynamically send value or completion events.
    ///                      You should return a `Cancelable`-conforming object
    ///                      from it to encapsulate any cleanup-logic for your work.
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    AnyPublisher<String, MyError>.create { subscriber in
    ///        // Values
    ///        subscriber.send("Hello")
    ///        subscriber.send("World!")
    ///
    ///        // Complete with error
    ///        subscriber.send(completion: .failure(MyError.someError))
    ///
    ///        // Or, complete successfully
    ///        subscriber.send(completion: .finished)
    ///
    ///        return AnyCancellable {
    ///          // Perform clean-up
    ///        }
    ///    }
    ///
    init(_ factory: @escaping Publishers.Create<Output, Failure>.SubscriberHandler) {
        self = Publishers.Create(factory: factory).eraseToAnyPublisher()
    }

    /// Create a publisher which accepts a closure with a subscriber argument,
    /// to which you can dynamically send value or completion events.
    ///
    /// You should return a `Cancelable`-conforming object from the closure in
    /// which you can define any cleanup actions to execute when the pubilsher
    /// completes or the subscription to the publisher is canceled.
    ///
    /// - parameter factory: A factory with a closure to which you can
    ///                      dynamically send value or completion events.
    ///                      You should return a `Cancelable`-conforming object
    ///                      from it to encapsulate any cleanup-logic for your work.
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    AnyPublisher<String, MyError>.create { subscriber in
    ///        // Values
    ///        subscriber.send("Hello")
    ///        subscriber.send("World!")
    ///
    ///        // Complete with error
    ///        subscriber.send(completion: .failure(MyError.someError))
    ///
    ///        // Or, complete successfully
    ///        subscriber.send(completion: .finished)
    ///
    ///        return AnyCancellable {
    ///          // Perform clean-up
    ///        }
    ///    }
    ///
    static func create(_ factory: @escaping Publishers.Create<Output, Failure>.SubscriberHandler)
        -> AnyPublisher<Output, Failure> {
        AnyPublisher(factory)
    }
}

// MARK: - Publisher
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publishers {
    /// A publisher which accepts a closure with a subscriber argument,
    /// to which you can dynamically send value or completion events.
    ///
    /// You should return a `Cancelable`-conforming object from the closure in
    /// which you can define any cleanup actions to execute when the pubilsher
    /// completes or the subscription to the publisher is canceled.
    struct Create<Output, Failure: Swift.Error>: Publisher {
        public typealias SubscriberHandler = (Subscriber) -> Cancellable
        private let factory: SubscriberHandler

        /// Initialize the publisher with a provided factory
        ///
        /// - parameter factory: A factory with a closure to which you can
        ///                      dynamically push value or completion events
        public init(factory: @escaping SubscriberHandler) {
            self.factory = factory
        }

        public func receive<S: Combine.Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            subscriber.receive(subscription: Subscription(factory: factory, downstream: subscriber))
        }
    }
}

// MARK: - Subscription
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension Publishers.Create {
    class Subscription<Downstream: Combine.Subscriber>: Combine.Subscription where Output == Downstream.Input, Failure == Downstream.Failure {
        private let buffer: DemandBuffer<Downstream>
        private var cancelable: Cancellable?

        init(factory: @escaping SubscriberHandler,
             downstream: Downstream) {
            self.buffer = DemandBuffer(subscriber: downstream)

            let subscriber = Subscriber(onValue: { [weak self] in _ = self?.buffer.buffer(value: $0) },
                                        onCompletion: { [weak self] in self?.buffer.complete(completion: $0) })

            self.cancelable = factory(subscriber)
        }

        func request(_ demand: Subscribers.Demand) {
            _ = self.buffer.demand(demand)
        }

        func cancel() {
            self.cancelable?.cancel()
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Create.Subscription: CustomStringConvertible {
    var description: String {
        return "Create.Subscription<\(Output.self), \(Failure.self)>"
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publishers.Create {
    struct Subscriber {
        private let onValue: (Output) -> Void
        private let onCompletion: (Subscribers.Completion<Failure>) -> Void

        fileprivate init(onValue: @escaping (Output) -> Void,
                         onCompletion: @escaping (Subscribers.Completion<Failure>) -> Void) {
            self.onValue = onValue
            self.onCompletion = onCompletion
        }

        /// Sends a value to the subscriber.
        ///
        /// - Parameter value: The value to send.
        public func send(_ input: Output) {
            onValue(input)
        }

        /// Sends a completion event to the subscriber.
        ///
        /// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
        public func send(completion: Subscribers.Completion<Failure>) {
            onCompletion(completion)
        }
    }
}
#endif
