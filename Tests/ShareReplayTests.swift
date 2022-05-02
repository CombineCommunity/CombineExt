//
//  ShareReplayTests.swift
//  CombineExtTests
//
//  Created by Jasdev Singh on 4/13/20.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class ShareReplayTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()

    private enum AnError: Error {
        case someError
    }

    func testSharingNoReplay() {
        var subscribeCount = 0

        let publisher = Publishers.Create<Int, Never> { subscriber in
            subscribeCount += 1
            subscriber.send(1)
            subscriber.send(2)
            subscriber.send(3)
            subscriber.send(completion: .finished)

            return AnyCancellable { }
        }
        .share(replay: 0)

        publisher
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)

        publisher
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)

        publisher
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)

        XCTAssertEqual(subscribeCount, 1)
    }

    func testSharingSingleReplay() {
        let subject = CurrentValueSubject<Int, Never>(1)

        let publisher = subject
            .share(replay: 1)

        var results = [Int]()

        publisher
            .sink(receiveValue: { results.append($0) })
            .store(in: &subscriptions)

        subject.send(2)

        XCTAssertEqual(results, [1, 2])
    }

    func testSharingManyReplay() {
        let subject = PassthroughSubject<Int, Never>()

        var results1 = [Int]()
        var results2 = [Int]()

        let publisher = subject
            .share(replay: 3)

        publisher
            .sink(receiveValue: { results1.append($0) })
            .store(in: &subscriptions)

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)

        publisher
            .sink(receiveValue: { results2.append($0) })
            .store(in: &subscriptions)

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

        publisher
            .sink(
                receiveCompletion: { completions1.append($0) },
                receiveValue: { results1.append($0) }
            )
            .store(in: &subscriptions)

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)
        subject.send(completion: .finished)

        publisher
            .sink(
                receiveCompletion: { completions2.append($0) },
                receiveValue: { results2.append($0) }
            )
            .store(in: &subscriptions)

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

        publisher
            .sink(
                receiveCompletion: { completions1.append($0) },
                receiveValue: { results1.append($0) }
            )
            .store(in: &subscriptions)

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)
        subject.send(completion: .failure(.someError))

        publisher
            .sink(
                receiveCompletion: { completions2.append($0) },
                receiveValue: { results2.append($0) }
            )
            .store(in: &subscriptions)

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

        publisher
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { results.append($0) }
            )
            .store(in: &subscriptions)

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

        publisher
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { results.append($0) }
            )
            .store(in: &subscriptions)

        subject.send(completion: .failure(.someError))
        subject.send(1)

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(completions, [.failure(.someError)])
    }
    
    func testSharingDoesNotRetainClassBasedPublisher() {
        var results = [Int]()
        var completions = [Subscribers.Completion<Never>]()
        
        var source: PassthroughSubject? = PassthroughSubject<Int, Never>()
        weak var weakSource = source
        
        var stream = source?.share(replay: 1)

        stream?
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { results.append($0) }
            )
            .store(in: &subscriptions)
        
        source?.send(1)
        source?.send(completion: .finished)
        
        subscriptions.forEach({ $0.cancel() })
        stream = nil
        source = nil
        
        XCTAssertEqual(results, [1])
        XCTAssertEqual(completions, [.finished])
        XCTAssertNil(weakSource)
    }

    func testSequentialUpstreamWithShareReplay() {
        let publisher = Just(1)
            .eraseToAnyPublisher()
            .share(replay: 1)

        var valueReceived = false
        var finishedReceived = false

        Publishers.Zip(publisher, publisher)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        finishedReceived = true
                    case let .failure(error):
                        XCTFail("Unexpected completion - failure: \(error).")
                    }
                },
                receiveValue: { leftValue, rightValue in
                    XCTAssertEqual(leftValue, 1)
                    XCTAssertEqual(rightValue, 1)

                    valueReceived = true
                }
            )
            .store(in: &subscriptions)

        XCTAssertTrue(valueReceived)
        XCTAssertTrue(finishedReceived)
    }
}
#endif
