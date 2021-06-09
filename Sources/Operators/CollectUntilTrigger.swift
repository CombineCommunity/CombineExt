//
//  CollectUntilTrigger.swift
//  CombineExt
//
//  Created by ferologics on 09/06/2021.
//  Copyright © 2021 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    func collect<CollectionTrigger>(
        until trigger: CollectionTrigger
    ) -> AnyPublisher<[Output], Failure> where
        CollectionTrigger: Publisher,
        CollectionTrigger.Output == Void,
        CollectionTrigger.Failure == Never {
        var events = [Output]()

        let eventPublisher = PassthroughSubject<[Output], Failure>()
        var cancellables = [AnyCancellable]()

        self.sink { completion in
            eventPublisher.send(completion: completion)
        } receiveValue: { output in
            events.append(output)
        }
        .store(in: &cancellables)

        trigger.sink { _ in
            eventPublisher.send(events)
            events = []
        }
        .store(in: &cancellables)

        func cleanUp() {
            cancellables.forEach { $0.cancel() }
            cancellables = []
        }

        return eventPublisher
            .handleEvents(
                receiveCompletion: { _ in cleanUp() },
                receiveCancel: { cleanUp() }
            )
            .eraseToAnyPublisher()
    }
}
#endif
