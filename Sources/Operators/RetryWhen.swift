//
//  RetryWhen.swift
//  CombineExt
//
//  Created by Daniel Tartaglia on 3/21/20.
//

import Combine

public extension Publisher {
    /**
     Repeats the source publisher on error when the notifier emits a next value.
     If the source publisher errors and the notifier completes, it will complete the source sequence.
     
     - parameter notificationHandler: A handler that is passed a publisher of errors raised by the source publisher and returns a publisher that either continues, completes or errors. This behavior is then applied to the source publisher.
     - returns: A publisher producing the elements of the given sequence repeatedly until it terminates successfully or is notified to error or complete.
     */
    func retryWhen<Trigger>(_ notificationHandler: @escaping (AnyPublisher<Self.Failure, Never>) -> Trigger)
        -> Publishers.RetryWhen<Self, Trigger, Output, Failure> where Trigger: Publisher {
            .init(upstream: self, notificationHandler: notificationHandler)
    }
}

public extension Publishers {
    class RetryWhen<Upstream, Trigger, Output, Failure>: Publisher where Upstream: Publisher, Upstream.Output == Output, Upstream.Failure == Failure, Trigger: Publisher, Trigger.Failure == Upstream.Failure {
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
        private var sink: Sink<Downstream>?
        private var cancellable: AnyCancellable?
        
        init(upstream: Upstream, downstream: Downstream, handler: @escaping (AnyPublisher<Upstream.Failure, Never>) -> Trigger) {
            self.upstream = upstream
            self.downstream = downstream
            self.sink = Sink(upstream: upstream, downstream: downstream, errorSubject: errorSubject)
            self.cancellable = handler(errorSubject.eraseToAnyPublisher())
                .sink(
                    receiveCompletion: { [unowned self] completion in
                        self.downstream.receive(completion: completion)
                    },
                    receiveValue: { [unowned self] _ in
                        guard let sink = self.sink else { return }
                        self.upstream.subscribe(sink)
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

extension Publishers.RetryWhen {
    class Sink<Downstream: Subscriber>: Subscriber where Output == Upstream.Output, Upstream.Output == Downstream.Input, Failure == Downstream.Failure {
        typealias TransformFailure = (Upstream.Failure) -> Downstream.Failure?
        
        private(set) var buffer: DemandBuffer<Downstream>
        private var upstreamSubscription: Combine.Subscription?
        private let errorSubject: PassthroughSubject<Upstream.Failure, Never>
        
        init(upstream: Upstream,
             downstream: Downstream,
             errorSubject: PassthroughSubject<Upstream.Failure, Never>) {
            self.buffer = DemandBuffer(subscriber: downstream)
            self.errorSubject = errorSubject
        }
        
        func demand(_ demand: Subscribers.Demand) {
            let newDemand = buffer.demand(demand)
            upstreamSubscription?.requestIfNeeded(newDemand)
        }
        
        func receive(subscription: Combine.Subscription) {
            upstreamSubscription = subscription
        }
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            return buffer.buffer(value: input)
        }
        
        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            switch completion {
            case .finished:
                buffer.complete(completion: .finished)
            case .failure(let error):
                cancelUpstream()
                errorSubject.send(error)
            }
        }
        
        func cancelUpstream() {
            upstreamSubscription.kill()
        }
        
        deinit { cancelUpstream() }
    }    
}

extension Publishers.RetryWhen.Subscription: CustomStringConvertible {
    var description: String {
        return "RetryWhen.Subscription<\(Output.self), \(Failure.self)>"
    }
}
