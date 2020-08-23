//
//  MergeManyTests.swift
//  CombineExtTests
//
//  Created by Joe Walsh on 8/17/20.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Foundation

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class MergeManyTests: XCTestCase {
    private var subscription: AnyCancellable!

    private enum MergeManyError: Error {
        case anError
    }

    func testOneEmissionMerging() {
        let first = PassthroughSubject<Int, Never>()
        let second = PassthroughSubject<Int, Never>()
        let third = PassthroughSubject<Int, Never>()

        var results = [Int]()
        var completed = false

        subscription = [first, second, third]
            .merge()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        first.send(1)
        second.send(2)
        third.send(3)

        XCTAssertEqual(results, [1, 2, 3])
        XCTAssertFalse(completed)
        
        first.send(completion: .finished)
        second.send(completion: .finished)
        third.send(completion: .finished)
        
        XCTAssertTrue(completed)
    }

    func testMultipleEmissionMergingEndingWithAnError() {
        let first = PassthroughSubject<Int, MergeManyError>()
        let second = PassthroughSubject<Int, MergeManyError>()
        let third = PassthroughSubject<Int, MergeManyError>()

        var results = [Int]()
        var completed: Subscribers.Completion<MergeManyError>?

        subscription = [first, second, third]
            .merge()
            .sink(receiveCompletion: { completed = $0 },
                  receiveValue: { results.append($0) })

        first.send(1)
        first.send(1)
        first.send(1)
        first.send(1)

        second.send(2)
        second.send(2)
        second.send(2)

        third.send(3)
        third.send(3)

        XCTAssertEqual(results, [1, 1, 1, 1, 2, 2, 2, 3, 3])
        XCTAssertNil(completed)
        first.send(completion: .failure(.anError))
        XCTAssertEqual(completed, .failure(.anError))
    }

    func testNoEmissionMerging() {
        let first = PassthroughSubject<Int, MergeManyError>()
        let second = PassthroughSubject<Int, MergeManyError>()
        let third = PassthroughSubject<Int, MergeManyError>()

        var results = [Int]()
        var completed = false

        subscription = [first, second, third]
            .merge()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        first.send(1)
        second.send(2)

        // Gated by `third` not emitting.

        XCTAssertEqual(results, [1, 2])
        XCTAssertFalse(completed)
    }

    func testMergingEndingWithAFinishedCompletion() {
        let first = PassthroughSubject<Int, Never>()
        let second = PassthroughSubject<Int, Never>()
        let third = PassthroughSubject<Int, Never>()

        var results = [Int]()
        var completed: Subscribers.Completion<Never>?

        subscription = [first, second, third]
            .merge()
            .sink(receiveCompletion: { completed = $0 },
                  receiveValue: { results.append($0) })

        first.send(1)

        second.send(2)
        second.send(2)

        third.send(3)

        XCTAssertEqual(results, [1, 2, 2, 3])
        XCTAssertNil(completed)
        first.send(completion: .finished)
        second.send(completion: .finished)
        third.send(completion: .finished)
        XCTAssertEqual(completed, .finished)
    }

    func testMergingWithAnInnerCompletionButNotAnOuter() {
        let first = PassthroughSubject<Int, Never>()
        let second = PassthroughSubject<Int, Never>()
        let third = PassthroughSubject<Int, Never>()

        var results = [Int]()
        var completed: Subscribers.Completion<Never>?

        subscription = first
            .merge(with: second, third)
            .sink(receiveCompletion: { completed = $0 },
                  receiveValue: { results.append($0) })

        first.send(1)
        first.send(1)

        second.send(2)
        second.send(2)

        third.send(3)

        XCTAssertEqual(results, [1, 1, 2, 2, 3])
        XCTAssertNil(completed)
        first.send(completion: .finished) // Doesn’t trigger a completion since only one publisher is finished
        XCTAssertNil(completed)
    }

    func testMergingCollection() {
        let first = PassthroughSubject<Int, Never>()
        let second = PassthroughSubject<Int, Never>()
        let third = PassthroughSubject<Int, Never>()

        var results = [Int]()
        var completed: Subscribers.Completion<Never>?

        subscription = [first, second, third]
            .merge()
            .sink(receiveCompletion: { completed = $0 },
                  receiveValue: { results.append($0) })

        first.send(1)

        second.send(2)
        second.send(2)

        third.send(3)

        XCTAssertEqual(results, [1, 2, 2, 3])
        XCTAssertNil(completed)
        
        first.send(completion: .finished)
        second.send(completion: .finished)
        third.send(completion: .finished)
        
        XCTAssertEqual(completed, .finished)
    }

    func testMergingWithASinglePublisher() {
        let first = PassthroughSubject<Int, Never>()

        var completed = false
        var results = [Int]()

        subscription = [first]
            .merge()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        first.send(1)

        XCTAssertEqual(results, [1])
        XCTAssertFalse(completed)

        first.send(completion: .finished)

        XCTAssertTrue(completed)
    }

    func testMergingWithNoPublishers() {
        var completed = false
        var results = [Int]()

        subscription = [AnyPublisher<Int, Never>]()
            .merge()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        XCTAssertTrue(results.isEmpty)
        XCTAssertTrue(completed)
    }
}
#endif
