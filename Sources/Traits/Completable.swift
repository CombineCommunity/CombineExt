//
//  Completable.swift
//  CombineExt
//
//  Created by Shai Mishali on 23/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

/// A `Publisher` that emits no values. It can only publish a
/// `.finished` or `.failue(Failuer)` event. This makes it extremely
/// useful for cases when you want to indicate something _has_
/// completed, but not the _result_ of that completion.
public struct Completable<Failure: Swift.Error>: Publisher {
    public typealias Output = Never

    private let upstream: AnyPublisher<Never, Failure>

    /// Create a `Completable` from a different publilsher, dropping
    /// all of its values and only passing-through its finishing events
    init<P: Publisher>(_ publisher: P) where P.Failure == Failure {
        self.upstream = publisher.ignoreOutput().eraseToAnyPublisher()
    }

    public func receive<S: Combine.Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        subscriber.receive(subscription: Subscription(upstream: upstream, downstream: subscriber))
    }
}

// MARK: - Creation
public extension Completable {
    /// Create a publisher which accepts a closure with a subscriber argument,
    /// to which you can dynamically send a completion event.
    ///
    /// You should return a `Cancelable`-conforming object from the closure in
    /// which you can define any cleanup actions to execute when the pubilsher
    /// completes or the subscription to the publisher is canceled.
    ///
    /// - parameter factory: A factory with a closure to which you can
    ///                      dynamically send a completion event.
    ///                      You should return a `Cancelable`-conforming object
    ///                      from it to encapsulate any cleanup-logic for your work.
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    Completable<MyError>.create { subscriber in
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
    init(factory: @escaping (Completable.Subscriber) -> Cancellable) {
        self = Completable<Failure>.create(factory)
    }

    /// Create a publisher which accepts a closure with a subscriber argument,
    /// to which you can dynamically send a completion event.
    ///
    /// You should return a `Cancelable`-conforming object from the closure in
    /// which you can define any cleanup actions to execute when the pubilsher
    /// completes or the subscription to the publisher is canceled.
    ///
    /// - parameter factory: A factory with a closure to which you can
    ///                      dynamically send a completion event.
    ///                      You should return a `Cancelable`-conforming object
    ///                      from it to encapsulate any cleanup-logic for your work.
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    Completable<MyError>.create { subscriber in
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
    static func create(_ factory: @escaping (Completable.Subscriber) -> Cancellable)
        -> Completable<Failure> {
        AnyPublisher<Output, Failure> { subscriber in
            return factory(.init(onCompletion: subscriber.onCompletion))
        }
        .asCompletable()
    }
}

// MARK: - Completable Subscriber
public extension Completable {
    struct Subscriber {
        private let onCompletion: (Subscribers.Completion<Failure>) -> Void

        fileprivate init(onCompletion: @escaping (Subscribers.Completion<Failure>) -> Void) {
            self.onCompletion = onCompletion
        }

        /// Sends a completion event to the subscriber.
        ///
        /// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
        public func send(completion: Subscribers.Completion<Failure>) {
            onCompletion(completion)
        }
    }
}

// MARK: - Publisher to Completable
public extension Publisher {
    /// Create a `Completable` from this publilsher, dropping all of
    /// its values and only passing-through its finishing events
    func asCompletable() -> Completable<Failure> {
        Completable(self)
    }
}

// MARK: - Completion-only `sink`
public extension Publisher where Output == Never {
    /// Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited number of events, prior to returning the subscriber.
    ///
    /// - parameter receiveComplete: The closure to execute on completion.
    ///
    /// - Returns: A cancellable instance; used when you end assignment of the received events. Deallocation of the result will tear down the subscription stream.
    func sink(receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void)) -> AnyCancellable {
        sink(receiveCompletion: { receiveCompletion($0) },
             receiveValue: { _ in })
    }
}

// MARK: - Subscription
private extension Completable {
    class Subscription<Upstream: Publisher, Downstream: Combine.Subscriber>: Combine.Subscription where Downstream.Input == Never, Upstream.Failure == Downstream.Failure {
        private var sink: Sink<Upstream, Downstream>?

        init(upstream: Upstream, downstream: Downstream) {
            self.sink = Sink(upstream: upstream, downstream: downstream)
        }

        func request(_ demand: Subscribers.Demand) {
            sink?.demand(demand)
        }

        func cancel() {
            sink = nil
        }
    }
}

// MARK: - Sink
private extension Completable {
    class Sink<Upstream: Publisher, Downstream: Combine.Subscriber>: CombineExt.Sink<Upstream, Downstream> where Downstream.Input == Never, Upstream.Failure == Downstream.Failure {
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            buffer.complete(completion: completion)
        }

        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            // Do nothing with incoming values
            // A completable can only complete or fail
            return .none
        }
    }
}

extension Completable.Subscription: CustomStringConvertible {
    var description: String {
        return "Completable.Subscription<\(Failure.self)>"
    }
}
#endif
