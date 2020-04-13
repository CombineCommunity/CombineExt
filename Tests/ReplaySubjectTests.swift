//
//  ReplaySubjectTests.swift
//  CombineExtTests
//
//  Created by Jasdev Singh on 4/13/20.
//

import Combine
@testable import CombineExt
import XCTest

final class ReplaySubjectTests: XCTestCase {
    private var cancellable1: AnyCancellable!
    private var cancellable2: AnyCancellable!
    private var cancellable3: AnyCancellable!

    private enum  AnError: Error, Equatable {
        case someError
    }

    func testReplaysNoValues() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 1)

        var results = [Int]()

        cancellable1 = subject
            .sink(receiveValue: { results.append($0) })

        XCTAssertTrue(results.isEmpty)
    }

    func testMissedValueWithEmptyBuffer() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 0)

        subject.send(1)

        var results = [Int]()

        cancellable1 = subject
            .sink(receiveValue: { results.append($0) })

        subject.send(2)

        XCTAssertEqual(results, [2])
    }

    func testMissedValueWithSingletonBuffer() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 1)

        subject.send(1)

        var results = [Int]()

        cancellable1 = subject
            .sink(receiveValue: { results.append($0) })

        subject.send(2)

        XCTAssertEqual(results, [1, 2])
    }

    func testMissedValuesWithManyBuffer() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 3)

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)

        var results = [Int]()

        cancellable1 = subject
            .sink(receiveValue: { results.append($0) })

        subject.send(5)

        XCTAssertEqual(results, [2, 3, 4, 5])
    }

    func testMissedValuesWithManyBufferUnfilled() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 3)

        subject.send(1)
        subject.send(2)

        var results = [Int]()

        cancellable1 = subject
            .sink(receiveValue: { results.append($0) })

        subject.send(3)

        XCTAssertEqual(results, [1, 2, 3])
    }

    func testMultipleSubscribers() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 3)

        subject.send(1)
        subject.send(2)

        var results1 = [Int]()
        var results2 = [Int]()
        var results3 = [Int]()

        XCTAssertEqual(subject.subscriptions.count, 0)
        XCTAssertEqual(subject.subscriberIdentifiers.count, 0)

        cancellable1 = subject
            .sink(receiveValue: { results1.append($0) })

        cancellable2 = subject
            .sink(receiveValue: { results2.append($0) })

        cancellable3 = subject
            .sink(receiveValue: { results3.append($0) })

        XCTAssertEqual(subject.subscriptions.count, 3)
        XCTAssertEqual(subject.subscriberIdentifiers.count, 3)

        subject.send(3)

        XCTAssertEqual(results1, [1, 2, 3])
        XCTAssertEqual(results2, [1, 2, 3])
        XCTAssertEqual(results3, [1, 2, 3])
    }

    func testCompletionWithMultipleSubscribers() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 3)

        subject.send(1)
        subject.send(2)
        subject.send(completion: .finished)

        var results1 = [Int]()
        var completions1 = [Subscribers.Completion<Never>]()

        var results2 = [Int]()
        var completions2 = [Subscribers.Completion<Never>]()

        var results3 = [Int]()
        var completions3 = [Subscribers.Completion<Never>]()

        cancellable1 = subject
            .sink(
                receiveCompletion: { completions1.append($0) },
                receiveValue: { results1.append($0) }
            )

        cancellable2 = subject
            .sink(
                receiveCompletion: { completions2.append($0) },
                receiveValue: { results2.append($0) }
            )

        cancellable3 = subject
            .sink(
                receiveCompletion: { completions3.append($0) },
                receiveValue: { results3.append($0) }
            )

        subject.send(3)

        XCTAssertEqual(results1, [1, 2])
        XCTAssertEqual(completions1, [.finished])

        XCTAssertEqual(results2, [1, 2])
        XCTAssertEqual(completions2, [.finished])

        XCTAssertEqual(results3, [1, 2])
        XCTAssertEqual(completions3, [.finished])
    }

    func testErrorWithMultipleSubscribers() {
        let subject = ReplaySubject<Int, AnError>(maxBufferSize: 3)

        subject.send(1)
        subject.send(2)
        subject.send(completion: .failure(.someError))

        var results1 = [Int]()
        var completions1 = [Subscribers.Completion<AnError>]()

        var results2 = [Int]()
        var completions2 = [Subscribers.Completion<AnError>]()

        var results3 = [Int]()
        var completions3 = [Subscribers.Completion<AnError>]()

        cancellable1 = subject
            .sink(
                receiveCompletion: { completions1.append($0) },
                receiveValue: { results1.append($0) }
            )

        cancellable2 = subject
            .sink(
                receiveCompletion: { completions2.append($0) },
                receiveValue: { results2.append($0) }
            )

        cancellable3 = subject
            .sink(
                receiveCompletion: { completions3.append($0) },
                receiveValue: { results3.append($0) }
            )

        subject.send(3)

        XCTAssertEqual(results1, [1, 2])
        XCTAssertEqual(completions1, [.failure(.someError)])

        XCTAssertEqual(results2, [1, 2])
        XCTAssertEqual(completions2, [.failure(.someError)])

        XCTAssertEqual(results3, [1, 2])
        XCTAssertEqual(completions3, [.failure(.someError)])
    }

    func testValueAndCompletionPreSubscribe() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 1)

        subject.send(1)
        subject.send(completion: .finished)

        var results1 = [Int]()
        var completed = false

        cancellable1 = subject
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results1.append($0) }
        )

        XCTAssertEqual(results1, [1])
        XCTAssertTrue(completed)
    }

    func testNoValuesReplayedPostCompletion() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 1)

        subject.send(1)
        subject.send(completion: .finished)
        subject.send(2)

        var results1 = [Int]()
        var completed = false

        cancellable1 = subject
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results1.append($0) }
        )

        XCTAssertEqual(results1, [1])
        XCTAssertTrue(completed)
    }

    func testNoValuesReplayedPostError() {
        let subject = ReplaySubject<Int, AnError>(maxBufferSize: 1)

        subject.send(1)
        subject.send(completion: .failure(.someError))
        subject.send(2)

        var results1 = [Int]()
        var completed = false

        cancellable1 = subject
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results1.append($0) }
        )

        XCTAssertEqual(results1, [1])
        XCTAssertTrue(completed)
    }

    func testDoubleSubscribe() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 1)

        subject.send(1)
        subject.send(completion: .finished)

        var results = [Int]()
        var completions = [Subscribers.Completion<Never>]()

        let sink1 = Subscribers.Sink<Int, Never>(
            receiveCompletion: { completions.append($0) },
            receiveValue: { results.append($0) }
        )

        subject
            .subscribe(sink1)

        subject
            .subscribe(sink1)

        XCTAssertEqual(results, [1])
        XCTAssertEqual(completions, [.finished, .finished])
    }

    func testSubscriberIdentifiers() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 1)

        let subscriber = AnySubscriber<Int, Never>()
        let subscriberIdentifier = subscriber.combineIdentifier

        subject
            .subscribe(subscriber)

        XCTAssertEqual(Array(subject.subscriberIdentifiers), [subscriberIdentifier])
        XCTAssertEqual(subject.subscriptions.count, 1)
    }

    func testCancellation() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 1)

        cancellable1 = subject
            .sink(receiveValue: { _ in })

        cancellable1.cancel()

        XCTAssertTrue(subject.subscriptions.isEmpty)
    }

    private var demandSubscription: Subscription!
    func testRespectsDemand() {
        let subject = ReplaySubject<Int, Never>(maxBufferSize: 4)

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)

        var results = [Int]()
        var completed = false

        let subscriber = AnySubscriber<Int, Never>(
            receiveSubscription: { subscription in
                self.demandSubscription = subscription
                subscription.request(.max(3))
            },
            receiveValue: { results.append($0); return .none },
            receiveCompletion: { _ in completed = true }
        )

        subject
            .subscribe(subscriber)

        XCTAssertEqual(results, [1, 2, 3])
        XCTAssertFalse(completed)

        subject.send(completion: .finished)

        XCTAssertTrue(completed)
    }
}
