//
//  PrefixDurationTests.swift
//  CombineExtTests
//
//  Created by David Ohayon and Jasdev Singh on 24/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Combine
import CombineExt
import CombineSchedulers
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class PrefixDurationTests: XCTestCase {
    private var cancellable: AnyCancellable!

    func testValueEventInWindow() {
        let scheduler = DispatchQueue.test

        let subject = PassthroughSubject<Int, Never>()

        var results = [Int]()
        var completions = [Subscribers.Completion<Never>]()

        cancellable = subject
            .prefix(duration: 0.5, on: scheduler)
            .sink(receiveCompletion: { completions.append($0) },
                  receiveValue: { results.append($0) })

        scheduler.schedule(after: scheduler.now.advanced(by: 0.25)) {
            subject.send(1)
        }

        scheduler.schedule(after: scheduler.now.advanced(by: 1.5)) {
            subject.send(2)
        }

        scheduler.advance(by: 2)

        XCTAssertEqual(results, [1])
        XCTAssertEqual(completions, [.finished])
    }

    func testMultipleEventsInAndOutOfWindow() {
        let subject = PassthroughSubject<Int, Never>()
        let scheduler = DispatchQueue.test

        var results = [Int]()
        var completions = [Subscribers.Completion<Never>]()

        cancellable = subject
            .prefix(duration: 0.8, on: scheduler)
            .sink(receiveCompletion: { completions.append($0) },
                  receiveValue: { results.append($0) })

        subject.send(1)

        scheduler.schedule(after: scheduler.now.advanced(by: 0.25)) {
            subject.send(2)
        }

        scheduler.schedule(after: scheduler.now.advanced(by: 0.4)) {
            subject.send(3)
        }

        scheduler.schedule(after: scheduler.now.advanced(by: 1)) {
            subject.send(4)
            subject.send(5)
            subject.send(completion: .finished)
        }

        scheduler.advance(by: 2)

        XCTAssertEqual(results, [1, 2, 3])
        XCTAssertEqual(completions, [.finished])
    }

    func testNoValueEventsInWindow() {
        let subject = PassthroughSubject<Int, Never>()
        let scheduler = DispatchQueue.test

        var results = [Int]()
        var completions = [Subscribers.Completion<Never>]()

        cancellable = subject
            .prefix(duration: 0.5, on: scheduler)
            .sink(receiveCompletion: { completions.append($0 ) },
                  receiveValue: { results.append($0) })

        scheduler.schedule(after: scheduler.now.advanced(by: 1.5)) {
            subject.send(1)
        }

        scheduler.advance(by: 2)

        XCTAssertTrue(results.isEmpty)
    }

    func testFinishedInWindow() {
        let subject = PassthroughSubject<Int, Never>()
        let scheduler = DispatchQueue.test

        var results = [Subscribers.Completion<Never>]()

        cancellable = subject
            .prefix(duration: 0.5, on: scheduler)
            .sink(receiveCompletion: { results.append($0) },
                  receiveValue: { _ in })

        scheduler.schedule(after: scheduler.now.advanced(by: 0.25)) {
            subject.send(completion: .finished)
        }

        scheduler.advance(by: 2)

        XCTAssertEqual(results, [.finished])
    }

    private enum AnError: Error {
        case someError
    }

    func testErrorInWindow() {
        let subject = PassthroughSubject<Int, AnError>()
        let scheduler = DispatchQueue.test

        var results = [Subscribers.Completion<AnError>]()

        cancellable = subject
            .prefix(duration: 0.5, on: scheduler)
            .sink(receiveCompletion: { results.append($0) },
                  receiveValue: { _ in })

        scheduler.schedule(after: scheduler.now.advanced(by: 0.25)) {
            subject.send(completion: .failure(.someError))
        }

        scheduler.advance(by: 2)

        XCTAssertEqual(results, [.failure(.someError)])
    }

    func testErrorEventOutsideWindowDoesntAffectFinishEvent() {
        let subject = PassthroughSubject<Int, AnError>()
        let scheduler = DispatchQueue.test

        var results = [Subscribers.Completion<AnError>]()

        cancellable = subject
            .prefix(duration: 0.5, on: scheduler)
            .sink(receiveCompletion: { results.append($0) },
                  receiveValue: { _ in })

        scheduler.schedule(after: scheduler.now.advanced(by: 0.75)) {
            subject.send(completion: .failure(.someError))
        }

        scheduler.advance(by: 2)

        XCTAssertEqual(results, [.finished])
    }
}
#endif
