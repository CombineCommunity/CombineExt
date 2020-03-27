//
//  AsFuture.swift
//  CombineExt
//
//  Created by Jullianm on 27/03/2020.
//  Copyright © 2020 Jullianm. All rights reserved.
//

import Combine

extension Publisher {
    /// Converts any publisher to a future.
    ///
    /// - returns: A publisher that eventually produces a single value and then finishes or fails.
    func asFuture() -> Publishers.Future<Self> {
        return Publishers.Future(upstream: self)
    }
}

extension Publishers {
    struct Future<Upstream: Publisher>: Publisher {
        typealias Output = Upstream.Output
        typealias Failure = Upstream.Failure
        
        private let upstream: Upstream
        
        init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            subscriber.receive(subscription: Subscription(upstream: upstream, downstream: subscriber))
        }
    }
}

extension Publishers.Future {
    class Subscription<Upstream: Publisher, Downstream: Subscriber>: Combine.Subscription where Upstream.Output == Downstream.Input, Upstream.Failure == Downstream.Failure {
        private var sink: AsFutureSink<Upstream, Downstream>?
        
        init(upstream: Upstream, downstream: Downstream) {
            sink = .init(upstream: upstream, downstream: downstream)
        }
        
        func request(_ demand: Subscribers.Demand) {}
        
        func cancel() {
            sink = nil
        }
    }
}

/// A generic sink limitating the current flow to a single value and immediately completing.
///
/// An empty sequence results in a `fatalError`.
class AsFutureSink<Upstream: Publisher, Downstream: Subscriber>: Subscriber where Upstream.Output == Downstream.Input, Downstream.Failure == Upstream.Failure {
    private var downstream: Downstream
    private var _element: Upstream.Output?

    init(upstream: Upstream, downstream: Downstream) {
        self.downstream = downstream
        upstream.subscribe(self)
    }

    func receive(subscription: Subscription) {
        subscription.request(.max(1))
    }

    func receive(_ input: Upstream.Output) -> Subscribers.Demand {
        _element = input
        _ = downstream.receive(input)
        downstream.receive(completion: .finished)
        
        return .none
    }

    func receive(completion: Subscribers.Completion<Upstream.Failure>) {
        switch completion {
        case .failure(let err):
            downstream.receive(completion: .failure(err))
        case .finished:
            if _element == nil {
                fatalError("❌ Sequence doesn't contain any elements.")
            }
        }
    }
}

