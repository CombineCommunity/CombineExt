//
//  FlatMapBatchesTests.swift
//  CombineExtTests
//
//  Created by Jasdev Singh on 23/01/2021.
//  Copyright © 2021 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class FlatMapBatchesTests: XCTestCase {
    private var subscription: AnyCancellable!

    private enum BatchedSubscribeError: Error, Equatable {
        case anError
    }

    func testEvenBatches() {
        let ints = (1...6).map(Just.init)

        var results = [[Int]]()
        var completed = false

        subscription = ints
            .flatMapBatches(of: 2)
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        XCTAssertEqual(results, [[1, 2], [3, 4], [5, 6]])
        XCTAssertTrue(completed)
    }

    func testUnevenBatches() {
        let ints = (1...5).map(Just.init)

        var results = [[Int]]()
        var completed = false

        subscription = ints
            .flatMapBatches(of: 2)
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        XCTAssertEqual(results, [[1, 2], [3, 4], [5]])
        XCTAssertTrue(completed)
    }

    func testForwardsError() {
        let publishers = [Fail(error: BatchedSubscribeError.anError).eraseToAnyPublisher()] +
            (1...3).map {
                Just($0)
                    .setFailureType(to: BatchedSubscribeError.self)
                    .eraseToAnyPublisher()
            }

        var results = [[Int]]()
        var completion: Subscribers.Completion<BatchedSubscribeError>?

        subscription = publishers
            .flatMapBatches(of: 2)
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { results.append($0) })

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(completion, .failure(.anError))
    }

    func testHangsIfEarlierBatchDoesntComplete() {
        let uncompleted = (1...2).map { number in
            AnyPublisher<Int, Never>.create { subscriber in
                subscriber.send(number)
                return AnyCancellable { }
            }
        }

        let publishers = uncompleted +
            (3...4).map(Just.init).map(AnyPublisher.init)

        var results = [[Int]]()
        var completed = false

        subscription = publishers
            .flatMapBatches(of: 2)
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        XCTAssertEqual(results, [[1, 2]])
        XCTAssertFalse(completed)
    }

    func testEmptyCollection() {
        let publishers = EmptyCollection<AnyPublisher<Int, Never>>()

        var results = [[Int]]()
        var completed = false

        subscription = publishers
            .flatMapBatches(of: 2)
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        XCTAssertTrue(results.isEmpty)
        XCTAssertTrue(completed)
    }

    func testBatchLimitLargerThanCount() {
        let ints = [Just(1)]

        var results = [[Int]]()
        var completed = false

        subscription = ints
            .flatMapBatches(of: 2)
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        XCTAssertEqual(results, [[1]])
        XCTAssertTrue(completed)
    }

    func testMultipleOutputsPerPublisher() {
        let publishers = (1...2).map { number in
            AnyPublisher<Int, Never>.create { subscriber in
                subscriber.send(number)
                subscriber.send(number)
                subscriber.send(completion: .finished)

                return AnyCancellable { }
            }
        } +
        (3...4).map(Just.init).map(AnyPublisher.init)

        var results = [[Int]]()
        var completed = false

        subscription = publishers
            .flatMapBatches(of: 2)
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        XCTAssertEqual(results, [[1, 2], [1, 2], [3, 4]])
        XCTAssertTrue(completed)
    }
}
#endif
