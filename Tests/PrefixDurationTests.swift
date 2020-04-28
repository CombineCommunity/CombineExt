//
//  PrefixDurationTests.swift
//  CombineExtTests
//
//  Created by David Ohayon and Jasdev Singh on 24/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine
import CombineExt
import XCTest

final class PrefixDurationTests: XCTestCase {
    private var cancellable: AnyCancellable!

    func testValueEventInWindow() {
        let subject = PassthroughSubject<Int, Never>()
        let expectation = XCTestExpectation()

        var results = [Int]()

        cancellable = subject
            .prefix(duration: 0.5)
            .sink(receiveCompletion: { _ in expectation.fulfill() },
                  receiveValue: { results.append($0) })

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            subject.send(1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            subject.send(2)
        }

        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(results, [1])
    }

    func testNoValueEventsInWindow() {
        let subject = PassthroughSubject<Int, Never>()
        let expectation = XCTestExpectation()

        var results = [Int]()

        cancellable = subject
            .prefix(duration: 0.5)
            .sink(receiveCompletion: { _ in expectation.fulfill() },
                  receiveValue: { results.append($0) })

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            subject.send(1)
        }

        wait(for: [expectation], timeout: 2)

        XCTAssertTrue(results.isEmpty)
    }

    func testFinishedInWindow() {
        let subject = PassthroughSubject<Int, Never>()
        let expectation = XCTestExpectation()

        var results = [Subscribers.Completion<Never>]()

        cancellable = subject
            .prefix(duration: 0.5)
            .sink(receiveCompletion: { results.append($0); expectation.fulfill() },
                  receiveValue: { _ in })

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            subject.send(completion: .finished)
        }

        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(results, [.finished])
    }

    private enum AnError: Error {
        case someError
    }

    func testErrorInWindow() {
        let subject = PassthroughSubject<Int, AnError>()
        let expectation = XCTestExpectation()

        var results = [Subscribers.Completion<AnError>]()

        cancellable = subject
            .prefix(duration: 0.5)
            .sink(receiveCompletion: { results.append($0); expectation.fulfill() },
                  receiveValue: { _ in })

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            subject.send(completion: .failure(.someError))
        }

        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(results, [.failure(.someError)])
    }

    func testErrorEventOutsideWindowDoesntAffectFinishEvent() {
        let subject = PassthroughSubject<Int, AnError>()
        let expectation = XCTestExpectation()

        var results = [Subscribers.Completion<AnError>]()

        cancellable = subject
            .prefix(duration: 0.5)
            .sink(receiveCompletion: { results.append($0); expectation.fulfill() },
                  receiveValue: { _ in })

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            subject.send(completion: .failure(.someError))
        }

        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(results, [.finished])
    }
}
