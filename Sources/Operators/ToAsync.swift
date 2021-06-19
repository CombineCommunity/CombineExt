//
//  ToAsync.swift
//  CombineExt
//
//  Created by Thibault Wittemberg on 2021-06-15.
//  Copyright © 2021 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension Future {
    func toAsync() async -> Output where Failure == Never {
        var subscriptions = [AnyCancellable]()

        return await withCheckedContinuation { [weak self] (continuation: CheckedContinuation<Output, Never>) in
            self?
                .sink { output in continuation.resume(returning: output) }
                .store(in: &subscriptions)
        }
    }

    func toAsync() async throws -> Output {
        var subscriptions = [AnyCancellable]()

        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Output, Error>) in
            self?
                .sink(
                    receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                },
                    receiveValue: { output in continuation.resume(returning: output) }
                )
                .store(in: &subscriptions)
        }
    }
}

// TODO: AsyncStream is not bundled with Xcode yet
//@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
//public extension Publisher {
//    func toAsync() async -> AsyncStream<Output> where Failure == Never {
//        var subscriptions = [AnyCancellable]()
//
//        return AsyncStream(Output.self) { [weak self] continuation in
//            self?
//                .sink { output in continuation.yield(output) }
//                .store(in: &subscriptions)
//        }
//    }
//}

#endif
