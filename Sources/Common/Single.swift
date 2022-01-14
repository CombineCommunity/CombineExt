//
//  Single.swift
//  CombineExt
//
//  Created by yjlee12 on 2022/01/14.
//

import Foundation

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publishers {
    struct Single<Upstream: Publisher>: Publisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure
        private let upstream: Upstream
        init(upstream: Upstream) {
            self.upstream = upstream
        }
        public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            subscriber.receive(subscription: Subscription(upstream: upstream, downstream: subscriber))
        }
        class Subscription<Downstream: Subscriber>: Combine.Subscription where Upstream.Output == Downstream.Input, Upstream.Failure == Downstream.Failure {
            private var sink: SingleSink<Upstream, Downstream>?
            
            init(upstream: Upstream, downstream: Downstream) {
                sink = .init(upstream: upstream, downstream: downstream)
            }
            func request(_ demand: Subscribers.Demand) { }
            func cancel() {
                sink = nil
            }
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public class SingleSink<Upstream: Publisher, Downstream: Subscriber>: Subscriber where Upstream.Output == Downstream.Input, Downstream.Failure == Upstream.Failure {
    private var downstream: Downstream
    private var _element: Upstream.Output?
    init(upstream: Upstream, downstream: Downstream) {
        self.downstream = downstream
        upstream.subscribe(self)
    }
    public func receive(subscription: Subscription) {
        subscription.request(.max(1))
    }
    public func receive(_ input: Upstream.Output) -> Subscribers.Demand {
        _element = input
        _ = downstream.receive(input)
        downstream.receive(completion: .finished)
        return .none
    }
    public func receive(completion: Subscribers.Completion<Upstream.Failure>) {
        switch completion {
        case .failure(let err):
            downstream.receive(completion: .failure(err))
        case .finished:
            if _element == nil {
                fatalError("❌ Sequence doesn’t contain any elements.")
            }
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    func asSingle() -> Publishers.Single<Self> {
        return Publishers.Single(upstream: self)
    }
}
#endif
