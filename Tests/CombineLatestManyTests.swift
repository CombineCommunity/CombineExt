//
//  CombineLatestManyTests.swift
//  CombineExtTests
//
//  Created by Jasdev Singh on 3/22/20.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class CombineLatestManyTests: XCTestCase {
    private var subscription: AnyCancellable!

    private enum CombineLatestManyTestError: Error {
        case anError
    }

    func testCollectionCombineLatestWithFinishedEvent() {
        let first = PassthroughSubject<Int, Never>()
        let second = PassthroughSubject<Int, Never>()
        let third = PassthroughSubject<Int, Never>()
        let fourth = PassthroughSubject<Int, Never>()

        var completed = false
        var results = [[Int]]()

        subscription = [first, second, third, fourth]
            .combineLatest()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        first.send(1)
        second.send(2)

        XCTAssertTrue(results.isEmpty)
        XCTAssertFalse(completed)

        third.send(3)
        fourth.send(4)

        XCTAssertEqual(results, [[1, 2, 3, 4]])
        XCTAssertFalse(completed)

        first.send(5)

        XCTAssertEqual(results, [[1, 2, 3, 4], [5, 2, 3, 4]])
        XCTAssertFalse(completed)

        fourth.send(6)

        XCTAssertEqual(results, [[1, 2, 3, 4], [5, 2, 3, 4], [5, 2, 3, 6]])
        XCTAssertFalse(completed)

        first.send(completion: .finished)

        XCTAssertEqual(results, [[1, 2, 3, 4], [5, 2, 3, 4], [5, 2, 3, 6]])
        XCTAssertFalse(completed)

        [second, third, fourth].forEach {
            $0.send(completion: .finished)
        }

        XCTAssertTrue(completed)
    }

    func testCollectionCombineLatestWithNoEvents() {
        let first = PassthroughSubject<Int, Never>()
        let second = PassthroughSubject<Int, Never>()

        var completed = false
        var results = [[Int]]()

        subscription = [first, second]
            .combineLatest()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        XCTAssertTrue(results.isEmpty)
        XCTAssertFalse(completed)
    }

    func testCollectionCombineLatestWithErrorEvent() {
        let first = PassthroughSubject<Int, CombineLatestManyTestError>()
        let second = PassthroughSubject<Int, CombineLatestManyTestError>()

        var completion: Subscribers.Completion<CombineLatestManyTestError>?
        var results = [[Int]]()

        subscription = [first, second]
            .combineLatest()
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { results.append($0) })

        first.send(1)
        second.send(2)

        XCTAssertEqual(results, [[1, 2]])
        XCTAssertNil(completion)

        second.send(completion: .failure(.anError))

        XCTAssertEqual(completion, .failure(.anError))
    }

    func testCollectionCombineLatestWithASinglePublisher() {
        let first = PassthroughSubject<Int, Never>()

        var completed = false
        var results = [[Int]]()

        subscription = [first]
            .combineLatest()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        first.send(1)

        XCTAssertEqual(results, [[1]])
        XCTAssertFalse(completed)

        first.send(completion: .finished)

        XCTAssertTrue(completed)
    }

    func testCollectionCombineLatestWithNoPublishers() {
        var completed = false
        var results = [[Int]]()

        subscription = [AnyPublisher<Int, Never>]()
            .combineLatest()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        XCTAssertTrue(results.isEmpty)
        XCTAssertTrue(completed)
    }

    func testMethodCombineLatestWithFinishedEvent() {
        let first = PassthroughSubject<Int, Never>()
        let second = PassthroughSubject<Int, Never>()

        var completed = false
        var results = [[Int]]()

        subscription = first.combineLatest(with: [second])
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        first.send(1)
        second.send(2)

        XCTAssertEqual(results, [[1, 2]])
        XCTAssertFalse(completed)

        second.send(3)
        second.send(3)

        XCTAssertEqual(results, [[1, 2], [1, 3], [1, 3]])
        XCTAssertFalse(completed)

        first.send(completion: .finished)

        XCTAssertFalse(completed)

        second.send(completion: .finished)

        XCTAssertTrue(completed)
    }

    func testVariadicMethodCombineLatest() {
        let first = PassthroughSubject<Int, Never>()
        let second = PassthroughSubject<Int, Never>()
        let third = PassthroughSubject<Int, Never>()
        let fourth = PassthroughSubject<Int, Never>()
        let fifth = PassthroughSubject<Int, Never>()

        var results = [[Int]]()

        subscription = first.combineLatest(with: second, third, fourth, fifth)
            .sink(receiveValue: { results.append($0) })

        first.send(1)
        second.send(2)
        third.send(3)
        fourth.send(4)
        fifth.send(5)

        XCTAssertEqual(results, [[1, 2, 3, 4, 5]])

        second.send(6)

        XCTAssertEqual(results, [[1, 2, 3, 4, 5], [1, 6, 3, 4, 5]])
    }

    func testCombineLatestAtScale() {
        // Using a combineLatest implementation that combines first/the-rest triggers a stack overflow using 1e5
        // publishers, but the divide-and-conquer implementation gets through 1e7 just fine (though the test takes
        // 28s to complete on an M1 Pro).
        let numPublishers = Int(1e5 + 1) // +1 to minimize the odds that numPublishers%4==0 matters.

        let publishers = Array(repeating: 1, count: numPublishers)
            .map { _ in Just(2) }
        var results = [[Int]]()
        subscription = publishers.combineLatest()
            .sink(receiveValue: { results.append($0) })
        let wantAllTwos = Array(repeating: 2, count: numPublishers)
        XCTAssertEqual(results, [wantAllTwos])
    }
}
#endif
