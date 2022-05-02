#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// Enumerates the elements of a publisher.
    /// - parameter initial: Initial index, default is 0.
    /// - returns: A publisher that contains tuples of upstream elements and their indexes.
    func enumerated(initial: Int = 0) -> Publishers.Enumerated<Self> {
        Publishers.Enumerated(upstream: self, initial: initial)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publishers {
    /// A publisher that enumerates the elements of another publisher by combining the index and element into a tuple.
    struct Enumerated<Upstream: Publisher>: Publisher {
        public typealias Output = (index: Int, element: Upstream.Output)
        public typealias Failure = Upstream.Failure

        public let upstream: Upstream
        public let initial: Int

        public init(upstream: Upstream, initial: Int = 0) {
            self.upstream = upstream
            self.initial = initial
        }

        public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
            upstream.subscribe(Inner(publisher: self, downstream: subscriber))
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension Publishers.Enumerated {
    final class Inner<Downstream: Subscriber>: Subscriber
    where Downstream.Input == Output, Downstream.Failure == Upstream.Failure {
        private var currentIndex: Int
        private let downstream: Downstream

        fileprivate init(
            publisher: Publishers.Enumerated<Upstream>,
            downstream: Downstream
        ) {
            self.currentIndex = publisher.initial
            self.downstream = downstream
        }

        func receive(subscription: Subscription) {
            downstream.receive(subscription: subscription)
        }

        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            defer { currentIndex += 1 }
            return downstream.receive((index: currentIndex, element: input))
        }

        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            downstream.receive(completion: completion)
        }
    }
}
#endif
