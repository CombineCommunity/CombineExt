//
//  RemoveAllDuplicatesTests.swift
//  CombineExtTests
//
//  Created by Jasdev Singh on 21/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class RemoveAllDuplicatesTests: XCTestCase {
    private var subscription: AnyCancellable!

    private enum RemoveAllDuplicatesTestError: Error {
        case anError
    }

    // MARK: - `Hashable`-related tests

    private struct HashableFour: Hashable {
        static let one = HashableFour(1)
        static let two = HashableFour(2)
        static let three = HashableFour(3)
        static let four = HashableFour(4)

        private let underlying: Int

        private init(_ underlying: Int) { self.underlying = underlying }
    }

    func testHashableExpectedDeduplication() {
        var results = [HashableFour]()

        subscription = [.one, .one, .two, .one, .three, .three, .four].publisher
            .removeAllDuplicates()
            .sink(receiveValue: { results.append($0) })

        XCTAssertEqual(results, [.one, .two, .three, .four])
    }

    func testHashableDeduplicationWithNoDuplicates() {
        var results = [HashableFour]()

        subscription = [.one, .two, .three, .four].publisher
            .removeAllDuplicates()
            .sink(receiveValue: { results.append($0) })

        XCTAssertEqual(results, [.one, .two, .three, .four])
    }

    func testHashableDeduplicationDoesntInterfereWithFinishEvents() {
        let integers = PassthroughSubject<HashableFour, Never>()

        var completion: Subscribers.Completion<Never>?
        var results = [HashableFour]()

        subscription = integers
            .removeAllDuplicates()
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { results.append($0) })

        integers.send(.one)
        integers.send(.two)
        integers.send(.three)
        integers.send(.four)
        integers.send(completion: .finished)

        XCTAssertEqual(results, [.one, .two, .three, .four])
        XCTAssertEqual(completion, .finished)
    }

    func testHashableDeduplicationDoesntInterfereWithErrorEvents() {
        let integers = PassthroughSubject<HashableFour, RemoveAllDuplicatesTestError>()

        var completion: Subscribers.Completion<RemoveAllDuplicatesTestError>?
        var results = [HashableFour]()

        subscription = integers
            .removeAllDuplicates()
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { results.append($0) })

        integers.send(.one)
        integers.send(.two)
        integers.send(.three)
        integers.send(.four)
        integers.send(completion: .failure(.anError))

        XCTAssertEqual(results, [.one, .two, .three, .four])
        XCTAssertEqual(completion, .failure(.anError))
    }

    // MARK: - `Equatable`-related tests

    private struct EquatableFour: Equatable {
        static let one = EquatableFour(1)
        static let two = EquatableFour(2)
        static let three = EquatableFour(3)
        static let four = EquatableFour(4)

        private let underlying: Int

        private init(_ underlying: Int) { self.underlying = underlying }
    }

    func testEquatableExpectedDeduplication() {
        var results = [EquatableFour]()

        subscription = [EquatableFour.one, .one, .two, .one, .three, .three, .four].publisher
            .removeAllDuplicates()
            .sink(receiveValue: { results.append($0) })

        XCTAssertEqual(results, [.one, .two, .three, .four])
    }

    func testEquatableDeduplicationWithNoDuplicates() {
        var results = [EquatableFour]()

        subscription = [EquatableFour.one, .two, .three, .four].publisher
            .removeAllDuplicates()
            .sink(receiveValue: { results.append($0) })

        XCTAssertEqual(results, [.one, .two, .three, .four])
    }

    func testEquatableDeduplicationDoesntInterfereWithFinishEvents() {
        let fours = PassthroughSubject<EquatableFour, Never>()

        var completion: Subscribers.Completion<Never>?
        var results = [EquatableFour]()

        subscription = fours
            .removeAllDuplicates()
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { results.append($0) })

        fours.send(.one)
        fours.send(.two)
        fours.send(.three)
        fours.send(.four)
        fours.send(completion: .finished)

        XCTAssertEqual(results, [.one, .two, .three, .four])
        XCTAssertEqual(completion, .finished)
    }

    func testEquatableDeduplicationDoesntInterfereWithErrorEvents() {
        let fours = PassthroughSubject<EquatableFour, RemoveAllDuplicatesTestError>()

        var completion: Subscribers.Completion<RemoveAllDuplicatesTestError>?
        var results = [EquatableFour]()

        subscription = fours
            .removeAllDuplicates()
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { results.append($0) })

        fours.send(.one)
        fours.send(.two)
        fours.send(.three)
        fours.send(.four)
        fours.send(completion: .failure(.anError))

        XCTAssertEqual(results, [.one, .two, .three, .four])
        XCTAssertEqual(completion, .failure(.anError))
    }

    // MARK: - Comparator-related tests

    private let isMultipleOf: (Int, Int) -> Bool = { seen, incoming in incoming.isMultiple(of: seen) }

    func testComparatorExpectedDeduplication() {
        var results = [Int]()

        subscription = [2, 3, 3, 4].publisher
            .removeAllDuplicates(by: isMultipleOf)
            .sink(receiveValue: { results.append($0) })

        XCTAssertEqual(results, [2, 3])
    }

    func testComparatorDeduplicationWithNoDuplicates() {
        var results = [Int]()

        subscription = [3, 5, 7, 11].publisher
            .removeAllDuplicates(by: isMultipleOf)
            .sink(receiveValue: { results.append($0) })

        XCTAssertEqual(results, [3, 5, 7, 11])
    }

    func testComparatorDeduplicationDoesntInterfereWithFinishEvents() {
        let integers = PassthroughSubject<Int, Never>()

        var completion: Subscribers.Completion<Never>?
        var results = [Int]()

        subscription = integers
            .removeAllDuplicates(by: isMultipleOf)
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { results.append($0) })

        integers.send(2)
        integers.send(3)
        integers.send(4)
        integers.send(completion: .finished)

        XCTAssertEqual(results, [2, 3])
        XCTAssertEqual(completion, .finished)
    }

    func testComparatorDeduplicationDoesntInterfereWithErrorEvents() {
        let integers = PassthroughSubject<Int, RemoveAllDuplicatesTestError>()

        var completion: Subscribers.Completion<RemoveAllDuplicatesTestError>?
        var results = [Int]()

        subscription = integers
            .removeAllDuplicates(by: isMultipleOf)
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { results.append($0) })

        integers.send(2)
        integers.send(3)
        integers.send(4)
        integers.send(completion: .failure(.anError))

        XCTAssertEqual(results, [2, 3])
        XCTAssertEqual(completion, .failure(.anError))
    }
}
#endif
