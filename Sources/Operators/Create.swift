//
//  Create.swift
//  CombineExt
//
//  Created by Shai Mishali on 13/03/2020.
//  Copyright © 2019 Combine Community. All rights reserved.
//

import Combine

public extension AnyPublisher {
    /// A publisher which accepts a factory closure to which you can
    /// dynamically push value or completion events
    ///
    /// - parameter factory: A factory with a closure to which you can
    ///                      dynamically push value or completion events
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    AnyPublisher<String, MyError>.create { subscriber in
    ///        // Values
    ///        subscriber(.value("Hello"))
    ///        subscriber(.value("World!"))
    ///
    ///        // Complete with error
    ///        subscriber(.error(MyError.someError))
    ///
    ///        // Or, complete successfully
    ///        subscriber(.finished)
    ///    }
    ///
    static func create(_ factory: @escaping Publishers.Create<Output, Failure>.Factory) -> AnyPublisher<Output, Failure> {
        Publishers.Create(factory: factory).eraseToAnyPublisher()
    }
}

// MARK: - Publisher
public extension Publishers {
    /// A publisher which accepts a factory closure to which you can
    /// dynamically push value or completion events
    ///
    /// An example usage could look as follows:
    ///
    ///    ```
    ///    Publishers.Create<String, MyError> { subscriber in
    ///        // Values
    ///        subscriber(.value("Hello"))
    ///        subscriber(.value("World!"))
    ///
    ///        // Complete with error
    ///        subscriber(.error(MyError.someError))
    ///
    ///        // Or, complete successfully
    ///        subscriber(.finished)
    ///    }
    ///    ```
    class Create<Output, Failure: Swift.Error>: Publisher {
        public typealias Factory = (@escaping (Event<Output, Failure>) -> Void) -> Void
        private let factory: Factory
        
        /// Initialize the publisher with a provided factory
        ///
        /// - parameter factory: A factory with a closure to which you can
        ///                      dynamically push value or completion events
        public init(factory: @escaping Factory) {
            self.factory = factory
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            subscriber.receive(subscription: Subscription(factory: factory, downstream: subscriber))
        }
    }
}

// MARK: - Subscription
private extension Publishers.Create {
    class Subscription<Downstream: Subscriber>: Combine.Subscription where Output == Downstream.Input, Failure == Downstream.Failure {
        private let buffer: DemandBuffer<Downstream>

        init(factory: @escaping Factory,
             downstream: Downstream) {
            self.buffer = DemandBuffer(subscriber: downstream)
         
            factory { [weak buffer] event in
                guard let buffer = buffer else { return }

                switch event {
                case .value(let output):
                    _ = buffer.buffer(value: output)
                case .failure(let error):
                    buffer.complete(completion: .failure(error))
                case .finished:
                    buffer.complete(completion: .finished)
                }
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            _ = self.buffer.demand(demand)
        }
        
        func cancel() { }
    }
}

extension Publishers.Create.Subscription: CustomStringConvertible {
    var description: String {
        return "Create.Subscription<\(Output.self), \(Failure.self)>"
    }
}
