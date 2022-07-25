//
//  FlatMapFirstTests.swift
//  CombineExtTests
//
//  Created by Martin Troup on 22/03/2022.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Combine
import CombineSchedulers
import Foundation
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class FlatMapFirstTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        cancellables = []
    }

    struct TestError: Error, Equatable {}

    func testSingleUpstreamSingleFlatMap() {
        let testScheduler = DispatchQueue.test

        var innerPublisherSubscriptionCount = 0
        var innerPublisherCompletionCount = 0
        var isUpstreamCompleted = false

        Just("").setFailureType(to: Never.self)
            .delay(for: 1, scheduler: testScheduler)
            .flatMapFirst { _ -> AnyPublisher<Date, Never> in
                return Just(Date())
                    .delay(for: 1, scheduler: testScheduler)
                    .handleEvents(
                        receiveSubscription: { _ in innerPublisherSubscriptionCount += 1 },
                        receiveCompletion: { _ in innerPublisherCompletionCount += 1 }
                    )
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        isUpstreamCompleted = true
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        testScheduler.advance(by: 2)

        XCTAssertEqual(innerPublisherSubscriptionCount, 1)
        XCTAssertEqual(innerPublisherCompletionCount, 1)
        XCTAssertTrue(isUpstreamCompleted)
    }

    func testErrorUpstreamSkippingFlatMap() {
        let testScheduler = DispatchQueue.test

        var innerPublisherSubscriptionCount = 0
        var isUpstreamCompleted = false

        Fail(error: TestError()).eraseToAnyPublisher()
            .delay(for: 1, scheduler: testScheduler)
            .flatMapFirst { (_: String) -> AnyPublisher<Date, TestError> in
                return Just(Date()).setFailureType(to: TestError.self)
                    .handleEvents(receiveSubscription: { _ in innerPublisherSubscriptionCount += 1 })
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        XCTAssertEqual(error, TestError())
                        isUpstreamCompleted = true
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        testScheduler.advance(by: 1)

        XCTAssertEqual(innerPublisherSubscriptionCount, 0)
        XCTAssertTrue(isUpstreamCompleted)
    }

    func testStandardProcessingOfFlatMapFirst() {
        let testScheduler = DispatchQueue.test

        var innerPublisherSubscriptionCount = 0
        var innerPublisherCompletionCount = 0
        var isUpstreamCompleted = false

        testScheduler.timerPublisher(every: 1)
            .autoconnect()
            .prefix(100)
            .flatMapFirst { _ -> AnyPublisher<Date, Never> in
                return Just(Date())
                    .handleEvents(
                        receiveSubscription: { _ in innerPublisherSubscriptionCount += 1 },
                        receiveCompletion: { _ in innerPublisherCompletionCount += 1 }
                    )
                    .delay(for: 10, scheduler: testScheduler)
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        isUpstreamCompleted = true
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        testScheduler.advance(by: 110)

        XCTAssertEqual(innerPublisherSubscriptionCount, 10)
        XCTAssertEqual(innerPublisherCompletionCount, 10)
        XCTAssertTrue(isUpstreamCompleted)
    }
}
#endif
