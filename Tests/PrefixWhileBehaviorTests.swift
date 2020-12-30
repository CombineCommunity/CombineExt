//
//  PrefixWhileBehaviorTests.swift
//  CombineExt
//
//  Created by Jasdev Singh on 29/12/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class PrefixWhileBehaviorTests: XCTestCase {
    private struct SomeError: Error, Equatable {}

    private var cancellable: AnyCancellable!

    func testExclusiveValueEventsWithFinished() {
        let intSubject = PassthroughSubject<Int, Never>()

        var values = [Int]()
        var completions = [Subscribers.Completion<Never>]()

        cancellable = intSubject
            .prefix(
                while: { $0 % 2 == 0 },
                behavior: .exclusive
            )
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { values.append($0) }
            )

        [0, 2, 4, 5]
            .forEach(intSubject.send)

        XCTAssertEqual(values, [0, 2, 4])
        XCTAssertEqual(completions, [.finished])
    }

    func testExclusiveValueEventsWithError() {
        let intSubject = PassthroughSubject<Int, SomeError>()

        var values = [Int]()
        var completions = [Subscribers.Completion<SomeError>]()

        cancellable = intSubject
            .prefix(
                while: { $0 % 2 == 0 },
                behavior: .exclusive
            )
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { values.append($0) }
            )

        [0, 2, 4]
            .forEach(intSubject.send)

        intSubject.send(completion: .failure(.init()))

        XCTAssertEqual(values, [0, 2, 4])
        XCTAssertEqual(completions, [.failure(.init())])
    }

    func testInclusiveValueEventsWithStopElement() {
        let intSubject = PassthroughSubject<Int, Never>()

        var values = [Int]()
        var completions = [Subscribers.Completion<Never>]()

        cancellable = intSubject
            .prefix(
                while: { $0 % 2 == 0 },
                behavior: .inclusive
            )
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { values.append($0) }
            )

        [0, 2, 4, 5]
            .forEach(intSubject.send)

        XCTAssertEqual(values, [0, 2, 4, 5])
        XCTAssertEqual(completions, [.finished])
    }

    func testInclusiveValueEventsWithErrorAfterStopElement() {
        let intSubject = PassthroughSubject<Int, SomeError>()

        var values = [Int]()
        var completions = [Subscribers.Completion<SomeError>]()

        cancellable = intSubject
            .prefix(
                while: { $0 % 2 == 0 },
                behavior: .inclusive
            )
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { values.append($0) }
            )

        [0, 2, 4, 5]
            .forEach(intSubject.send)

        intSubject.send(completion: .failure(.init()))

        XCTAssertEqual(values, [0, 2, 4, 5])
        XCTAssertEqual(completions, [.finished])
    }

    func testInclusiveValueEventsWithErrorBeforeStop() {
        let intSubject = PassthroughSubject<Int, SomeError>()

        var values = [Int]()
        var completions = [Subscribers.Completion<SomeError>]()

        cancellable = intSubject
            .prefix(
                while: { $0 % 2 == 0 },
                behavior: .inclusive
            )
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { values.append($0) }
            )

        [0, 2, 4]
            .forEach(intSubject.send)

        intSubject.send(completion: .failure(.init()))

        XCTAssertEqual(values, [0, 2, 4])
        XCTAssertEqual(completions, [.failure(.init())])
    }

    func testInclusiveEarlyCompletion() {
        let intSubject = PassthroughSubject<Int, SomeError>()

        var values = [Int]()
        var completions = [Subscribers.Completion<SomeError>]()

        cancellable = intSubject
            .prefix(
                while: { $0 % 2 == 0 },
                behavior: .inclusive
            )
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { values.append($0) }
            )

        [0, 2, 4]
            .forEach(intSubject.send)

        intSubject.send(completion: .finished)

        XCTAssertEqual(values, [0, 2, 4])
        XCTAssertEqual(completions, [.finished])
    }
}
#endif
