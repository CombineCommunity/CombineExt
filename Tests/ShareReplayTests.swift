//
//  ShareReplayTests.swift
//  CombineExtTests
//
//  Created by Jasdev Singh on 4/13/20.
//

import Combine
import CombineExt
import XCTest

final class ShareReplayTests: XCTestCase {
    private var cancellable1: AnyCancellable!
    private var cancellable2: AnyCancellable!
    private var cancellable3: AnyCancellable!

    private enum AnError: Error {
        case someError
    }

    func testSharingNoReplay() {
        var subscribeCount = 0

        let publisher = Publishers.Create<Int, Never> { handler in
            subscribeCount += 1
            handler(.value(1))
            handler(.value(2))
            handler(.value(3))
            handler(.finished)
        }
        .share(replay: 0)

        cancellable1 = publisher
            .sink(receiveValue: { _ in })

        cancellable2 = publisher
            .sink(receiveValue: { _ in })

        cancellable3 = publisher
            .sink(receiveValue: { _ in })

        XCTAssertEqual(subscribeCount, 1)
    }

    func testSharingSingleReplay() {
        let subject = CurrentValueSubject<Int, Never>(1)

        let publisher = subject
            .share(replay: 1)

        var results = [Int]()

        cancellable1 = publisher
            .sink(receiveValue: { results.append($0) })

        subject.send(2)

        XCTAssertEqual(results, [1, 2])
    }

    func testSharingManyReplay() {
        let subject = PassthroughSubject<Int, Never>()

        var results1 = [Int]()
        var results2 = [Int]()

        let publisher = subject
            .share(replay: 3)

        cancellable1 = publisher
            .sink(receiveValue: { results1.append($0) })

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)

        cancellable2 = publisher
            .sink(receiveValue: { results2.append($0) })

        XCTAssertEqual(results1, [1, 2, 3, 4])
        XCTAssertEqual(results2, [2, 3, 4])
    }

    func testSharingWithFinishedEvent() {
        let subject = PassthroughSubject<Int, Never>()

        var results1 = [Int]()
        var completions1 = [Subscribers.Completion<Never>]()

        var results2 = [Int]()
        var completions2 = [Subscribers.Completion<Never>]()

        let publisher = subject
            .share(replay: 3)

        cancellable1 = publisher
            .sink(
                receiveCompletion: { completions1.append($0) },
                receiveValue: { results1.append($0) }
            )

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)
        subject.send(completion: .finished)

        cancellable2 = publisher
            .sink(
                receiveCompletion: { completions2.append($0) },
                receiveValue: { results2.append($0) }
            )

        XCTAssertEqual(results1, [1, 2, 3, 4])
        XCTAssertEqual(completions1, [.finished])

        XCTAssertEqual(results2, [2, 3, 4])
        XCTAssertEqual(completions2, [.finished])
    }

    func testSharingWithErrorEvent() {
        let subject = PassthroughSubject<Int, AnError>()

        var results1 = [Int]()
        var completions1 = [Subscribers.Completion<AnError>]()

        var results2 = [Int]()
        var completions2 = [Subscribers.Completion<AnError>]()

        let publisher = subject
            .share(replay: 3)

        cancellable1 = publisher
            .sink(
                receiveCompletion: { completions1.append($0) },
                receiveValue: { results1.append($0) }
            )

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)
        subject.send(completion: .failure(.someError))

        cancellable2 = publisher
            .sink(
                receiveCompletion: { completions2.append($0) },
                receiveValue: { results2.append($0) }
            )

        XCTAssertEqual(results1, [1, 2, 3, 4])
        XCTAssertEqual(completions1, [.failure(.someError)])

        XCTAssertEqual(results2, [2, 3, 4])
        XCTAssertEqual(completions2, [.failure(.someError)])
    }

    func testFinishWithNoReplay() {
        let subject = PassthroughSubject<Int, Never>()

        var results = [Int]()
        var completions = [Subscribers.Completion<Never>]()

        let publisher = subject
            .share(replay: 1)

        cancellable1 = publisher
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { results.append($0) }
            )

        subject.send(completion: .finished)
        subject.send(1)

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(completions, [.finished])
    }

    func testErrorWithNoReplay() {
        let subject = PassthroughSubject<Int, AnError>()

        var results = [Int]()
        var completions = [Subscribers.Completion<AnError>]()

        let publisher = subject
            .share(replay: 1)

        cancellable1 = publisher
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { results.append($0) }
            )

        subject.send(completion: .failure(.someError))
        subject.send(1)

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(completions, [.failure(.someError)])
    }
}
