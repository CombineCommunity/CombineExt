//
//  FromAsyncTests.swift
//  CombineExtTests
//
//  Created by Thibault Wittemberg on 2021-06-15.
//  Copyright © 2021 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest

struct MockError: Error, Equatable {
    let value: Int
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
final class FromAsyncTests: XCTestCase {
    func testFromAsync_publishes_value_when_non_throwable_asyncFunction() {
        let exp = expectation(description: "fromAsync publishes the expected value when executing a non throwable asynchronous function")

        let expectedOutput = UUID().uuidString
        var receivedOutput: String?

        // Given: a non throwable async function
        // When: making the publisher from the function and subscribing to it
        let cancellable = Publishers
            .fromAsync { return expectedOutput }
            .handleEvents(receiveCompletion: { _ in exp.fulfill() })
            .sink { asyncOutput in receivedOutput = asyncOutput }

        waitForExpectations(timeout: 1)

        // Then: The value from the async function is published
        XCTAssertEqual(receivedOutput, expectedOutput)

        cancellable.cancel()
    }

    func testFromAsync_executes_asynFunction_with_specified_priority_when_non_throwable_asyncFunction() {
        let exp = expectation(description: "fromAsync uses the expected priority when executing a non throwable asynchronous function with a priority")

        let expectedQueue = "com.apple.root.user-initiated-qos.cooperative"
        var receivedQueue: String?

        // Given: a non throwable async function
        // When: making the publisher from the function and subscribing to it with a priority
        let cancellable = Publishers
            .fromAsync(priority: .userInitiated) { () async -> String in
                receivedQueue = DispatchQueue.currentLabel
                return ""
            }
            .handleEvents(receiveCompletion: { _ in exp.fulfill() })
            .sink { _ in }

        waitForExpectations(timeout: 1)

        // Then: The async function is executed with the expected priority
        XCTAssertEqual(receivedQueue, expectedQueue)

        cancellable.cancel()
    }

    func testFromThrowableAsync_publishes_value_when_throwable_asyncFunction() {
        let exp = expectation(description: "fromAsync publishes the expected value when executing a throwable asynchronous function")

        let expectedOutput = UUID().uuidString
        var receivedOutput: String?

        // Given: a throwable async function
        // When: making the publisher from the function and subscribing to it
        let cancellable = Publishers
            .fromThrowableAsync { return expectedOutput }
            .handleEvents(receiveCompletion: { _ in exp.fulfill() })
            .sink(receiveCompletion: { _ in }, receiveValue: { asyncOutput in receivedOutput = asyncOutput })

        waitForExpectations(timeout: 1)

        // Then: The value from the async function is published
        XCTAssertEqual(receivedOutput, expectedOutput)

        cancellable.cancel()
    }

    func testFromThrowableAsync_executes_asynFunction_with_specified_priority_when_throwable_asyncFunction() {
        let exp = expectation(description: "fromAsync uses the expected priority when executing a throwable asynchronous function with a priority")

        let expectedQueue = "com.apple.root.user-initiated-qos.cooperative"
        var receivedQueue: String?

        // Given: a throwable async function
        // When: making the publisher from the function and subscribing to it with a priority
        let cancellable = Publishers
            .fromThrowableAsync(priority: .userInitiated) { () async throws -> String in
                receivedQueue = DispatchQueue.currentLabel
                return ""
            }
            .handleEvents(receiveCompletion: { _ in exp.fulfill() })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        waitForExpectations(timeout: 1)

        // Then: The async function is executed with the expected priority
        XCTAssertEqual(receivedQueue, expectedQueue)

        cancellable.cancel()
    }

    func testFromThrowableAsync_completesWithFailure_when_throwable_asyncFunction() {
        let exp = expectation(description: "fromAsync completes with the expected failure when executing a throwing asynchronous function")

        let expectedError = MockError(value: Int.random(in: 0...100))
        var receivedError: Error?

        // Given: a throwing async function
        // When: making the publisher from the function and subscribing to it
        let cancellable = Publishers
            .fromThrowableAsync { throw expectedError }
            .handleEvents(receiveCompletion: { _ in exp.fulfill() })
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    receivedError = error
                }
            }, receiveValue: { _ in })

        waitForExpectations(timeout: 1)

        // Then: The error from the async function is catched in the completion
        XCTAssertEqual(receivedError as? MockError, expectedError)

        cancellable.cancel()
    }

    //    func testFromAsync_cancels_task_when_non_throwable_asyncFunction() {
    //        let exp = expectation(description: "")
    //
    //        let semaphore = DispatchSemaphore(value: 0)
    //        var isTaskCancelled = false
    //
    //        // Given: an async function that records the cancellation of its execution task
    //
    //        // When: making the publisher from the function and subscribing to it
    //        let cancellable = Publishers
    //            .fromAsync { () async -> String in
    //                semaphore.wait()
    //                isTaskCancelled = Task.isCancelled
    //                exp.fulfill()
    //                return ""
    //            }
    //            .subscribe(on: DispatchQueue(label: UUID().uuidString))
    //            .sink { _ in }
    //
    //        // When: cancelling the subscription
    //        cancellable.cancel()
    //        semaphore.signal()
    //
    //        waitForExpectations(timeout: 1)
    //
    //        // Then: the aync task has been cancelled
    //        XCTAssertTrue(isTaskCancelled)
    //    }

    func testFromAsync_publishes_the_values_from_a_non_throwing_asyncSequence() {
        let exp = expectation(description: "fromAsync publishes the expected values when executing a non throwable asynchronous sequence")

        struct AsyncCounter : AsyncSequence {
            typealias Element = Int

            let maxValue: Int

            struct AsyncIterator : AsyncIteratorProtocol {
                let maxValue: Int
                var current = 1
                mutating func next() async -> Int? {
                    guard current <= maxValue else {
                        return nil
                    }

                    let result = current
                    current += 1
                    return result
                }
            }

            func makeAsyncIterator() -> AsyncIterator {
                return AsyncIterator(maxValue: maxValue)
            }
        }

        let expectedValues = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        var receivedValues: [Int]?

        // Given: an async sequence
        let sut = AsyncCounter(maxValue: 10)

        // When: making the publisher from the sequence and subscribing to it
        let cancellable = Publishers
            .fromAsync(sut)
            .collect()
            .sink { completion in
                exp.fulfill()
            } receiveValue: { output in
                receivedValues = output
            }

        waitForExpectations(timeout: 1)

        // Then: the publisher publishes the values from the sequence
        XCTAssertEqual(receivedValues, expectedValues)

        cancellable.cancel()
    }

    func testFromAsync_completes_with_failure_when_asyncSequence_throws() {
        let exp = expectation(description: "fromAsync completes with error when async sequence fails")

        struct ThrowingAsyncCounter : AsyncSequence {
            typealias Element = Int

            let failWithError: MockError

            struct AsyncIterator : AsyncIteratorProtocol {
                let failWithError: MockError

                mutating func next() async throws -> Int? {
                    throw failWithError
                }
            }

            func makeAsyncIterator() -> AsyncIterator {
                return AsyncIterator(failWithError: self.failWithError)
            }
        }

        let expectedError = MockError(value: Int.random(in: 1...100))
        var receivedError: Error?

        // Given: an async sequence
        let sut = ThrowingAsyncCounter(failWithError: expectedError)

        // When: making the publisher from the sequence and subscribing to it
        let cancellable = Publishers
            .fromAsync(sut)
            .handleEvents(receiveCompletion: { _ in exp.fulfill() })
            .sink { completion in
                if case let .failure(error) = completion {
                    receivedError = error
                }
            } receiveValue: { _ in }


        waitForExpectations(timeout: 1)

        // Then: The error from the async sequence is catched in the completion
        XCTAssertEqual(receivedError as? MockError, expectedError)

        cancellable.cancel()
    }
}

fileprivate extension DispatchQueue {
    class var currentLabel: String {
        return String(validatingUTF8: __dispatch_queue_get_label(nil))!
    }
}
#endif
