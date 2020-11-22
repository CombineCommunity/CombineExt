//
//  ConcatMap.swift
//  CombineExt
//
//  Created by Daniel Peter on 22/11/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine
import class Foundation.NSRecursiveLock

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// Transforms an output value into a new publisher, and flattens the stream of events from these multiple upstream publishers to appear as if they were coming from a single stream of events.
    ///
    /// Mapping to a new publisher will keep the subscription to the previous one alive until it completes and only then subscribe to the new one. This also means that all values sent by the new publisher are not forwarded as long as the previous one hasn't completed.
    ///
    /// - parameter transform: A transform to apply to each emitted value, from which you can return a new Publisher
    ///
    /// - returns: A publisher emitting the values of all emitted publishers in order.
    func concatMap<T, P>(
        _ transform: @escaping (Self.Output) -> P
    ) -> Publishers.ConcatMap<P, Self> where T == P.Output, P: Publisher, Self.Failure == P.Failure {
        return Publishers.ConcatMap(upstream: self, transform: transform)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publishers {
    struct ConcatMap<NewPublisher, Upstream>: Publisher where NewPublisher: Publisher, Upstream: Publisher, NewPublisher.Failure == Upstream.Failure  {
        public typealias Transform = (Upstream.Output) -> NewPublisher
        public typealias Output = NewPublisher.Output
        public typealias Failure = Upstream.Failure

        public let upstream: Upstream
        public let transform: Transform

        public init(
            upstream: Upstream,
            transform: @escaping Transform
        ) {
            self.upstream = upstream
            self.transform = transform
        }

        public func receive<S: Subscriber>(subscriber: S)
        where Output == S.Input, Failure == S.Failure {
            subscriber.receive(
                subscription: Subscription(
                    upstream: upstream,
                    transform: transform,
                    downstream: subscriber
                )
            )
        }
    }
}

// MARK: - Subscription
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension Publishers.ConcatMap {
    final class Subscription<Downstream: Subscriber>: Combine.Subscription where Downstream.Input == Output, Downstream.Failure == Failure {
        private var sink: Sink<Downstream>?

        init(
            upstream: Upstream,
            transform: @escaping Transform,
            downstream: Downstream
        ) {
            self.sink = Sink(
                upstream: upstream,
                downstream: downstream,
                transform: { transform($0) }
            )
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
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension Publishers.ConcatMap {
    final class Sink<Downstream: Subscriber>: CombineExt.Sink<Upstream, Downstream> where Downstream.Input == Output, Downstream.Failure == Failure {
        private let lock = NSRecursiveLock()
        private let transform: Transform
        private var activePublisher: NewPublisher?
        private var bufferedPublishers: [NewPublisher]
        private var cancellables: Set<AnyCancellable>

        init(
            upstream: Upstream,
            downstream: Downstream,
            transform: @escaping Transform
        ) {
            self.transform = transform
            self.bufferedPublishers = []
            self.cancellables = []
            super.init(
                upstream: upstream,
                downstream: downstream,
                transformFailure: { $0 }
            )
        }

        override func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            let mapped = transform(input)

            lock.lock()
            if activePublisher == nil {
                lock.unlock()
                setActivePublisher(mapped)
            } else {
                lock.unlock()
                bufferedPublishers.append(mapped)
            }

            return .unlimited
        }

        private func setActivePublisher(_ publisher: NewPublisher) {
            lock.lock()
            defer { lock.unlock() }
            activePublisher = publisher

            publisher.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        self.lock.lock()
                        guard let next = self.bufferedPublishers.first else {
                            self.lock.unlock()
                            return
                        }
                        self.bufferedPublishers.removeFirst()
                        self.lock.unlock()
                        self.setActivePublisher(next)
                    case .failure(let error):
                        self.receive(completion: .failure(error))
                    }
                },
                receiveValue: { value in
                    _ = self.buffer.buffer(value: value)
                }
            )
            .store(in: &cancellables)
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.ConcatMap.Subscription: CustomStringConvertible {
    var description: String {
        return "ConcatMap.Subscription<\(Downstream.Input.self), \(Downstream.Failure.self)>"
    }
}
#endif
