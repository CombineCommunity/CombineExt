//
//  RetryWhen.swift
//  CombineExt
//
//  Created by Daniel Tartaglia on 3/21/20.
//

import Combine

public extension Publisher {

    /// Repeats the source publisher on error when the notifier emits a next value. If the source publisher errors and the notifier completes, it will complete the source sequence.
    ///
    /// - Parameter notificationHandler: A handler that is passed a publisher of errors raised by the source publisher and returns a publisher that either continues, completes or errors. This behavior is then applied to the source publisher.
    /// - Returns: A publisher producing the elements of the given sequence repeatedly until it terminates successfully or is notified to error or complete.
    func retryWhen<Trigger>(_ notificationHandler: @escaping (AnyPublisher<Self.Failure, Never>) -> Trigger)
        -> Publishers.RetryWhen<Self, Trigger, Output, Failure> where Trigger: Publisher {
            .init(upstream: self, notificationHandler: notificationHandler)
    }
}

public extension Publishers {
    class RetryWhen<Upstream, Trigger, Output, Failure>: Publisher where Upstream: Publisher, Upstream.Output == Output, Upstream.Failure == Failure, Trigger: Publisher, Trigger.Failure == Failure {
        typealias Handler = (AnyPublisher<Upstream.Failure, Never>) -> Trigger
        
        private let upstream: Upstream
        private let handler: Handler
        
        init(upstream: Upstream, notificationHandler: @escaping Handler) {
            self.upstream = upstream
            self.handler = notificationHandler
        }
        
        public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            subscriber.receive(subscription: Subscription(upstream: upstream, downstream: subscriber, handler: handler))
        }
    }
}

extension Publishers.RetryWhen {
    class Subscription<Downstream>: Combine.Subscription where Downstream: Subscriber, Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure {
        
        private let upstream: Upstream
        private let downstream: Downstream
        private let errorSubject = PassthroughSubject<Upstream.Failure, Never>()
        private var sink: Sink<Upstream, Downstream>?
        private var cancellable: AnyCancellable?
        
        init(upstream: Upstream, downstream: Downstream, handler: @escaping (AnyPublisher<Upstream.Failure, Never>) -> Trigger) {
            self.upstream = upstream
            self.downstream = downstream
            self.sink = Sink(
                downstream: downstream,
                transformOutput: { $0 },
                transformFailure: { [errorSubject] in
                    errorSubject.send($0)
                    return nil
                }
            )
            self.cancellable = handler(errorSubject.eraseToAnyPublisher())
                .sink(
                    receiveCompletion: { [sink] completion in
                       sink?.buffer.complete(completion: completion)
                    },
                    receiveValue: { [upstream, sink] _ in
                        guard let sink = sink else { return }
                        upstream.subscribe(sink)
                    }
            )
            upstream.subscribe(sink!)
        }
        
        func request(_ demand: Subscribers.Demand) {
            sink?.demand(demand)
        }
        
        func cancel() {
            sink = nil
        }
    }
}

extension Publishers.RetryWhen.Subscription: CustomStringConvertible {
    var description: String {
        return "RetryWhen.Subscription<\(Output.self), \(Failure.self)>"
    }
}
