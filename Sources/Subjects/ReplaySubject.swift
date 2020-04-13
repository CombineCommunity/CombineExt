//
//  ReplaySubject.swift
//  CombineExt
//
//  Created by Jasdev Singh on 13/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

/// `ReplaySubject` is a [CurrentValueSubject](https://developer.apple.com/documentation/combine/currentvaluesubject)
/// that can buffer, well, more than one value! It stores value events, up to its `maxBufferSize` in a
/// [first-in-first-out](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics)) manner and then replays it to
/// future subscribers and also forwards completion events.
///
/// The implementation borrows heavily from [Tristan’s](https://github.com/tcldr/Entwine/blob/b839c9fcc7466878d6a823677ce608da998b95b9/Sources/Entwine/Operators/ReplaySubject.swift)
/// with the main modifications being leaning on Shai’s [Sink](https://github.com/CombineCommunity/CombineExt/blob/7ed4677e33fdc963af404423cb563e133c271d2b/Sources/Common/Sink.swift)
/// instead of `Entwine`’s [SinkQueue](https://github.com/tcldr/Entwine/blob/b839c9fcc7466878d6a823677ce608da998b95b9/Sources/Common/Utilities/SinkQueue.swift)
/// and a plain ol’ `[Output]` buffer instead of a
/// [custom, LinkedListQueue-backed one](https://github.com/tcldr/Entwine/blob/8be24a59bc91410bb29e84b1c4ae35398a5839c8/Sources/Entwine/Operators/ReplaySubject.swift#L162-L177).
public final class ReplaySubject<Output, Failure: Error> {
    // MARK: - Private

    private let maxBufferSize: UInt
    private var buffer = [Output]()

    // MARK: - Internal

    var subscriptions = [Subscription<AnySubscriber<Output, Failure>>]()

    // We also track subscriber identifiers, to more quickly bottom-out double subscribes instead of having to do a
    // linear pass over `subscriptions`.
    var subscriberIdentifiers = Set<CombineIdentifier>()

    private var completion: Subscribers.Completion<Failure>?
    private var isActive: Bool { completion == nil }

    /// The initialization point for `ReplaySubject`s.
    /// - Parameter maxBufferSize: The maximum number of value events to buffer and replay to all future subscribers.
    public init(maxBufferSize: UInt) {
        self.maxBufferSize = maxBufferSize
    }
}

// MARK: - `Subject`

extension ReplaySubject: Subject {
    public func send(_ value: Output) {
        guard isActive else { return }

        buffer.append(value)

        if buffer.count > maxBufferSize {
            buffer.removeFirst()
        }

        subscriptions.forEach { $0.forwardValueToSink(value) }
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        guard isActive else { return }

        self.completion = completion

        subscriptions.forEach { $0.forwardCompletionToSink(completion) }
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
            subscriber.receive(completion: .finished)
            return
        }

        let subscription = Subscription(
            downstream: AnySubscriber(subscriber)
        ) { [weak self] in
            guard
                let self = self,
                let subscriptionIndex = self.subscriptions
                    .firstIndex(where: { $0.innerSubscriberIdentifier == subscriberIdentifier })
            else { return }

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
    final class Subscription<Downstream: Subscriber>
    where Output == Downstream.Input, Failure == Downstream.Failure {
        // MARK: - Private

        private var sink: Sink<Empty<Output, Failure>, Downstream>?
        private var cancelHandler: (() -> Void)?

        // MARK: - Internal

        let innerSubscriberIdentifier: CombineIdentifier

        init(
            downstream: Downstream,
            cancelHandler: (() -> Void)?
        ) {
            self.sink = Sink(
                upstream: Empty(completeImmediately: false), // `ReplaySubject`’s `Subject` conformance handles
                // forwarding down into the `sink` instance. So, we can pretend `Sink.upstream` is an `Empty`,
                // non-finishing publisher.
                downstream: downstream,
                transformOutput: { $0 },
                transformFailure: { $0 }
            )

            self.innerSubscriberIdentifier = downstream.combineIdentifier
            self.cancelHandler = cancelHandler
        }

        // MARK: - Internal helpers

        func replay(_ buffer: [Output], completion: Subscribers.Completion<Failure>?) {
            buffer.forEach(forwardValueToSink)

            if let completion = completion {
                forwardCompletionToSink(completion)
            }
        }

        func forwardValueToSink(_ value: Output) {
            _ = sink?.receive(value)
        }

        func forwardCompletionToSink(_ completion: Subscribers.Completion<Failure>) {
            _ = sink?.receive(completion: completion)
        }
    }
}

// MARK: - `Combine.Subscription`

extension ReplaySubject.Subscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        sink?.demand(demand)
    }
}

// MARK: - `Cancellable`

extension ReplaySubject.Subscription: Cancellable {
    func cancel() {
        cancelHandler?()
        cancelHandler = nil

        sink = nil
    }
}
