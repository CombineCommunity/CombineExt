//
//  Materialize.swift
//  CombineExt
//
//  Created by Shai Mishali on 14/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// Converts any publisher to a publisher of its events
    ///
    /// - note: The returned publisher is guaranteed to never fail,
    ///         but it will complete given any upstream completion event
    ///
    /// - returns: A publisher that wraps events in an `Event<Output, Failure>`.
    func materialize() -> Publishers.Materialize<Self> {
        return Publishers.Materialize(upstream: self)
    }
}

// MARK: - Materialized Operators
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Output: EventConvertible, Failure == Never {
    /// Given a materialized publisher, publish only the emitted
    /// upstream values, omitting failures
    ///
    /// - returns: A publisher emitting the `Output` of the wrapped event
    func values() -> AnyPublisher<Output.Output, Never> {
        compactMap {
            guard case .value(let value) = $0.event else { return nil }
            return value
        }
        .eraseToAnyPublisher()
    }

    /// Given a materialize publisher, publish only the emitted
    /// upstream failure, if exists, omitting values
    ///
    /// - returns: A publisher emitting the `Failure` of the wrapped event
    func failures() -> AnyPublisher<Output.Failure, Never> {
        compactMap {
            guard case .failure(let error) = $0.event else { return nil }
            return error
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Publisher
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publishers {
    /// A publisher which takes an upstream publisher and emits its events,
    /// wrapped in `Event<Output, Failure>`
    ///
    /// - note: This publisher is guaranteed to never fail, but it
    ///         will complete given any upstream completion event
    struct Materialize<Upstream: Publisher>: Publisher {
        public typealias Output = Event<Upstream.Output, Upstream.Failure>
        public typealias Failure = Never

        private let upstream: Upstream

        public init(upstream: Upstream) {
            self.upstream = upstream
        }

        public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            subscriber.receive(subscription: Subscription(upstream: upstream, downstream: subscriber))
        }
    }
}

// MARK: - Subscription
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension Publishers.Materialize {
    class Subscription<Downstream: Subscriber>: Combine.Subscription where Downstream.Input == Event<Upstream.Output, Upstream.Failure>, Downstream.Failure == Never {
        private var sink: Sink<Downstream>?

        init(upstream: Upstream,
             downstream: Downstream) {
            self.sink = Sink(upstream: upstream,
                             downstream: downstream,
                             transformOutput: { .value($0) })
        }

        func request(_ demand: Subscribers.Demand) {
            sink?.demand(demand)
        }

        func cancel() {
            sink?.cancelUpstream()
            sink = nil
        }
    }
}

// MARK: - Sink
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension Publishers.Materialize {
    class Sink<Downstream: Subscriber>: CombineExt.Sink<Upstream, Downstream>
    where Downstream.Input == Event<Upstream.Output, Upstream.Failure>, Downstream.Failure == Never {
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            // We're overriding the standard completion buffering mechanism
            // to buffer these events as regular materialized values, and send
            // a regular finished event in either case
            switch completion {
            case .finished:
                _ = buffer.buffer(value: .finished)
            case .failure(let error):
                _ = buffer.buffer(value: .failure(error))
            }

            buffer.complete(completion: .finished)
            cancelUpstream()
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Materialize.Subscription: CustomStringConvertible {
    var description: String {
        return "Materialize.Subscription<\(Downstream.Input.Output.self), \(Downstream.Input.Failure.self)>"
    }
}
#endif
