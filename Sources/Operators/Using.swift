//
//  Using.swift
//  CombineExt
//
//  Created by Daniel Tartaglia on 10/9/2021.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publishers {
    /// A publisher that ties the existence of  a resource to its subscription
    /// lifetime.
    ///
    /// A new resource will be created for each subscription. When the
    /// subscription closes or completes, the resourse's `cancel()` will be
    /// called then it will be deinited.
    struct Using<Resource, Pub, Output, Failure>: Publisher where Resource: Cancellable, Pub: Publisher, Pub.Output == Output, Pub.Failure == Failure {
        private let createResource: () -> Resource
        private let createPublisher: (Resource) -> Pub

        /// Constructs an publisher that depends on a resource object, whose
        /// lifetime is tied to the resulting publisher's subscription lifetime.
        ///
        /// - parameter resourceFactory: Factory function to obtain a resource
        ///                              object.
        /// - parameter publisherFactory: Factory function to obtain a publisher
        ///                               that depends on the obtained resource.
        /// - returns: An observable sequence whose lifetime controls the
        ///            lifetime of the dependent resource object.
        public init(_ resourceFactory: @escaping () -> Resource, publisherFactory: @escaping (Resource) -> Pub) {
            createResource = resourceFactory
            createPublisher = publisherFactory
        }

        public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            let resource = createResource()
            let publisher = createPublisher(resource)
            publisher
                .handleEvents(
                    receiveCompletion:  { _ in
                        resource.cancel()
                    },
                    receiveCancel: {
                        resource.cancel()
                    })
                .subscribe(subscriber)
        }
    }
}
#endif
