//
//  ReplaySubject.swift
//  CombineExt
//
//  Created by Jasdev Singh on 13/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

/// A `ReplaySubject` is a subject that can buffer one or more values. It stores value events, up to its `bufferSize` in a
/// [first-in-first-out](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics)) manner and then replays it to
/// future subscribers and also forwards completion events.
///
/// The implementation borrows heavily from [Entwine’s](https://github.com/tcldr/Entwine/blob/b839c9fcc7466878d6a823677ce608da998b95b9/Sources/Entwine/Operators/ReplaySubject.swift).
public final class ReplaySubject<Output, Failure: Error> {
    // MARK: - Private
    private let bufferSize: Int
    private var buffer = [Output]()

    // MARK: - Internal
    var subscriptions = [Subscription<AnySubscriber<Output, Failure>>]()

    // We also track subscriber identifiers, to more quickly bottom-out double subscribes instead of having to do a
    // linear pass over `subscriptions`.
    var subscriberIdentifiers = Set<CombineIdentifier>()

    private var completion: Subscribers.Completion<Failure>?
    private var isActive: Bool { completion == nil }

    /// Create a `ReplaySubject`, buffering up to `bufferSize` values and replaying them to new subscribers
    /// - Parameter bufferSize: The maximum number of value events to buffer and replay to all future subscribers.
    public init(bufferSize: Int) {
        self.bufferSize = bufferSize
    }
}

// MARK: - `Subject`

extension ReplaySubject: Subject {
    public func send(_ value: Output) {
        guard isActive else { return }

        buffer.append(value)

        if buffer.count > bufferSize {
            buffer.removeFirst()
        }

        subscriptions.forEach { $0.forwardValueToBuffer(value) }
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        guard isActive else { return }

        self.completion = completion

        subscriptions.forEach { $0.forwardCompletionToBuffer(completion) }
    }

    public func send(subscription: Combine.Subscription) {
        subscription.request(.unlimited)
    }
}

// MARK: - `Publisher`

extension ReplaySubject: Publisher {
    public typealias Output = Output
    public typealias Failure = Failure

    public func receive<Subscriber: Combine.Subscriber>(
        subscriber: Subscriber
    ) where Failure == Subscriber.Failure, Output == Subscriber.Input {
        let subscriberIdentifier = subscriber.combineIdentifier

        guard !subscriberIdentifiers.contains(subscriberIdentifier) else {
            subscriber.receive(subscription: Subscriptions.empty)
            return
        }

        let subscription = Subscription(
            downstream: AnySubscriber(subscriber)) { [weak self] in
            guard let self = self,
                  let subscriptionIndex = self.subscriptions
                                              .firstIndex(where: { $0.innerSubscriberIdentifier == subscriberIdentifier }) else { return }

            self.subscriberIdentifiers.remove(subscriberIdentifier)
            self.subscriptions.remove(at: subscriptionIndex)
        }

        subscriberIdentifiers.insert(subscriberIdentifier)
        subscriptions.append(subscription)

        subscriber.receive(subscription: subscription)
        subscription.replay(buffer, completion: completion)
    }
}

// MARK: - `ReplaySubject.Subscription`

extension ReplaySubject {
    final class Subscription<Downstream: Subscriber> where Output == Downstream.Input, Failure == Downstream.Failure {
        // MARK: - Private

        private var demandBuffer: DemandBuffer<Downstream>?
        private var cancellationHandler: (() -> Void)?

        // MARK: - Internal

        let innerSubscriberIdentifier: CombineIdentifier

        init(
            downstream: Downstream,
            cancellationHandler: (() -> Void)?
        ) {
            self.demandBuffer = DemandBuffer(subscriber: downstream)
            self.innerSubscriberIdentifier = downstream.combineIdentifier
            self.cancellationHandler = cancellationHandler
        }

        // MARK: - Internal helpers

        func replay(_ buffer: [Output], completion: Subscribers.Completion<Failure>?) {
            buffer.forEach(forwardValueToBuffer)

            if let completion = completion {
                forwardCompletionToBuffer(completion)
            }
        }

        func forwardValueToBuffer(_ value: Output) {
            _ = demandBuffer?.buffer(value: value)
        }

        func forwardCompletionToBuffer(_ completion: Subscribers.Completion<Failure>) {
            demandBuffer?.complete(completion: completion)
        }
    }
}

// MARK: - `Combine.Subscription`

extension ReplaySubject.Subscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        _ = demandBuffer?.demand(demand)
    }
}

// MARK: - `Cancellable`

extension ReplaySubject.Subscription: Cancellable {
    func cancel() {
        cancellationHandler?()
        cancellationHandler = nil

        demandBuffer = nil
    }
}
