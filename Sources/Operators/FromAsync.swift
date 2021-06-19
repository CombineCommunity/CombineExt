//
//  FromAsync.swift
//  CombineExt
//
//  Created by Thibault Wittemberg on 2021-06-15.
//  Copyright © 2021 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension Publishers {
    static func fromAsync<Output>(priority: Task.Priority? = nil,
                                  _ asyncFunction: @escaping () async -> Output) -> AnyPublisher<Output, Never> {
        AnyPublisher<Output, Never>.create { subscriber in
            let task = async(priority: priority) {
                let result = await asyncFunction()
                subscriber.send(result)
                subscriber.send(completion: .finished)
            }

            return AnyCancellable {
                task.cancel()
            }
        }
    }

    static func fromThrowableAsync<Output>(priority: Task.Priority? = nil,
                                           _ asyncFunction: @escaping () async throws -> Output) -> AnyPublisher<Output, Error> {
        AnyPublisher<Output, Error>.create { subscriber in
            let task = async(priority: priority) {
                do {
                    let result = try await asyncFunction()
                    subscriber.send(result)
                    subscriber.send(completion: .finished)
                } catch {
                    subscriber.send(completion: .failure(error))
                }
            }

            return AnyCancellable {
                task.cancel()
            }
        }
    }

    // TODO: Find a Never failure flavour

    static func fromAsync<Output, AsyncSequenceType>(priority: Task.Priority? = nil,
                                                     _ asyncSequence: AsyncSequenceType) -> AnyPublisher<Output, Error>
    where AsyncSequenceType: AsyncSequence, AsyncSequenceType.Element == Output {
        AnyPublisher<Output, Error>.create { subscriber in
            let task = async(priority: priority) {
                do {
                    for try await result in asyncSequence {
                        subscriber.send(result)
                    }
                    subscriber.send(completion: .finished)
                } catch {
                    subscriber.send(completion: .failure(error))
                }
            }

            return AnyCancellable {
                task.cancel()
            }
        }
    }
}
#endif
