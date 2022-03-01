#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// Delay subscription of upstream by specified interval.
    func delaySubscription<Scheduler: Combine.Scheduler>(
        for interval: Scheduler.SchedulerTimeType.Stride,
        tolerance: Scheduler.SchedulerTimeType.Stride? = nil,
        scheduler: Scheduler,
        options: Scheduler.SchedulerOptions? = nil
    ) -> Publishers.DelaySubscription<Self, Scheduler> {
        Publishers.DelaySubscription(
            upstream: self,
            interval: interval,
            tolerance: tolerance ?? scheduler.minimumTolerance,
            scheduler: scheduler,
            options: options
        )
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publishers {
    /// A publisher that delays subscription of upstream.
    struct DelaySubscription<Upstream: Publisher, Scheduler: Combine.Scheduler>: Publisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure

        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream

        /// The amount of time to delay.
        public let interval: Scheduler.SchedulerTimeType.Stride

        /// The allowed tolerance in firing delayed subscription.
        public let tolerance: Scheduler.SchedulerTimeType.Stride

        /// The scheduler for the delayed subscription.
        public let scheduler: Scheduler

        /// The options for the scheduler.
        public let options: Scheduler.SchedulerOptions?

        public init(
            upstream: Upstream,
            interval: Scheduler.SchedulerTimeType.Stride,
            tolerance: Scheduler.SchedulerTimeType.Stride,
            scheduler: Scheduler,
            options: Scheduler.SchedulerOptions? = nil
        ) {
            self.upstream = upstream
            self.interval = interval
            self.tolerance = tolerance
            self.scheduler = scheduler
            self.options = options
        }

        public func receive<S>(subscriber: S)
        where S: Subscriber, Upstream.Failure == S.Failure, Upstream.Output == S.Input {
            upstream.subscribe(Inner(publisher: self, downstream: subscriber))
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension Publishers.DelaySubscription {
    final class Inner<Downstream: Subscriber>: Subscriber
    where Downstream.Input == Output, Downstream.Failure == Upstream.Failure {
        typealias Input = Upstream.Output
        typealias Failure = Upstream.Failure

        private let interval: Scheduler.SchedulerTimeType.Stride
        private let tolerance: Scheduler.SchedulerTimeType.Stride
        private let scheduler: Scheduler
        private let options: Scheduler.SchedulerOptions?
        private let downstream: Downstream

        fileprivate init(
            publisher: Publishers.DelaySubscription<Upstream, Scheduler>,
            downstream: Downstream
        ) {
            self.interval = publisher.interval
            self.tolerance = publisher.tolerance
            self.scheduler = publisher.scheduler
            self.options = publisher.options
            self.downstream = downstream
        }

        func receive(subscription: Subscription) {
            scheduler.schedule(
                after: scheduler.now.advanced(by: interval),
                tolerance: tolerance,
                options: options
            ) { [weak self] in
                self?.downstream.receive(subscription: subscription)
            }
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            downstream.receive(input)
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            downstream.receive(completion: completion)
        }
    }
}
#endif
