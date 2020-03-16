//
//  ZipManyTests.swift
//  CombineExtTests
//
//  Created by Jasdev Singh on 16/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import XCTest
import Combine
import CombineExt

final class ZipManyTests: XCTestCase {
    private var subscription: AnyCancellable!

    private enum ZipManyError: Error {
        case anError
    }

    func testOneEmissionZipping() {
        let first = PassthroughSubject<Int, Never>()
        let second = PassthroughSubject<Int, Never>()
        let third = PassthroughSubject<Int, Never>()

        var results = [[Int]]()
        var completed = false

        subscription = first
            .zip(with: second, third)
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        first.send(1)
        second.send(2)
        third.send(3)

        XCTAssertEqual(results, [[1, 2, 3]])
        XCTAssertFalse(completed)
        first.send(completion: .finished)
        XCTAssertTrue(completed)
    }

    func testMultipleEmissionZippingEndingWithAnError() {
        let first = PassthroughSubject<Int, ZipManyError>()
        let second = PassthroughSubject<Int, ZipManyError>()
        let third = PassthroughSubject<Int, ZipManyError>()

        var results = [[Int]]()
        var completed: Subscribers.Completion<ZipManyError>?

        subscription = first
            .zip(with: second, third)
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

        XCTAssertEqual(results, [[1, 2, 3], [1, 2, 3]])
        XCTAssertNil(completed)
        first.send(completion: .failure(.anError))
        XCTAssertEqual(completed, .failure(.anError))
    }

    func testNoEmissionZipping() {
        let first = PassthroughSubject<Int, ZipManyError>()
        let second = PassthroughSubject<Int, ZipManyError>()
        let third = PassthroughSubject<Int, ZipManyError>()

        var results = [[Int]]()
        var completed = false

        subscription = first
            .zip(with: second, third)
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        first.send(1)
        second.send(2)

        // Gated by `third` not emitting.

        XCTAssertTrue(results.isEmpty)
        XCTAssertFalse(completed)
    }

    func testTransformedZipping() {
        let first = PassthroughSubject<Int, Never>()
        let second = PassthroughSubject<Int, Never>()
        let third = PassthroughSubject<Int, Never>()

        var results = [Int]()

        subscription = first
            .zip(with: second, third, transform: { $0.reduce(0, +) })
            .sink(receiveValue: { results.append($0) })

        first.send(1)
        second.send(2)
        third.send(3)

        XCTAssertEqual(results, [6])
    }

    func testTransformedZippingForArrayOverload() {
        let first = PassthroughSubject<Int, Never>()
        let second = PassthroughSubject<Int, Never>()
        let third = PassthroughSubject<Int, Never>()

        var results = [Int]()

        subscription = first
            .zip(with: [second, third], transform: { $0.reduce(1, *) })
            .sink(receiveValue: { results.append($0) })

        first.send(1)
        second.send(2)
        third.send(3)

        XCTAssertEqual(results, [6])
    }
}
