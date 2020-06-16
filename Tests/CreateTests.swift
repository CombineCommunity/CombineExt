//
//  CreateTests.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 14/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class CreateTests: XCTestCase {
    var subscription: AnyCancellable!
    enum MyError: Swift.Error {
        case failure
    }
    
    private var completion: Subscribers.Completion<CreateTests.MyError>?
    private var values = [String]()
    private var canceled = false
    private let allValues = ["Hello", "World", "What's", "Up?"]
    
    override func setUp() {
        canceled = false
        values = []
        completion = nil
    }
    
    func testUnlimitedDemandFinished() {
        let subscriber = makeSubscriber(demand: .unlimited)
        let publisher = makePublisher(fail: false)

        publisher.subscribe(subscriber)
        
        XCTAssertEqual(completion, .finished)
        XCTAssertTrue(canceled)
        XCTAssertEqual(values, allValues)
    }

    func testLimitedDemandFinished() {
        let subscriber = makeSubscriber(demand: .max(2))

        let publisher = AnyPublisher<String, MyError> { subscriber in
            self.allValues.forEach { subscriber.send($0) }
            subscriber.send(completion: .finished)

            return AnyCancellable { [weak self] in
                self?.canceled = true
            }
        }

        publisher.subscribe(subscriber)

        XCTAssertEqual(completion, .finished)
        XCTAssertTrue(canceled)
        XCTAssertEqual(values, Array(allValues.prefix(2)))
    }

    func testNoDemandFinished() {
        let subscriber = makeSubscriber(demand: .none)
        let publisher = makePublisher(fail: false)

        publisher.subscribe(subscriber)

        XCTAssertEqual(completion, .finished)
        XCTAssertTrue(canceled)
        XCTAssertTrue(values.isEmpty)
    }

    func testUnlimitedDemandError() {
        let subscriber = makeSubscriber(demand: .unlimited)
        let publisher = makePublisher(fail: true)

        publisher.subscribe(subscriber)

        XCTAssertEqual(completion, .failure(MyError.failure))
        XCTAssertTrue(canceled)
        XCTAssertEqual(values, allValues)
    }

    func testLimitedDemandError() {
        let subscriber = makeSubscriber(demand: .max(2))
        let publisher = makePublisher(fail: true)

        publisher.subscribe(subscriber)

        XCTAssertEqual(completion, .failure(MyError.failure))
        XCTAssertTrue(canceled)
        XCTAssertEqual(values, Array(allValues.prefix(2)))
    }

    func testNoDemandError() {
        let subscriber = makeSubscriber(demand: .none)
        let publisher = makePublisher(fail: true)

        publisher.subscribe(subscriber)

        XCTAssertEqual(completion, .failure(MyError.failure))
        XCTAssertTrue(canceled)
        XCTAssertTrue(values.isEmpty)
    }

    var cancelable: Cancellable?
    func testManualCancelation() {
        let publisher = AnyPublisher<String, Never>.create { _ in
            return AnyCancellable { [weak self] in self?.canceled = true }
        }

        cancelable = publisher.sink { _ in }
        XCTAssertFalse(canceled)
        cancelable?.cancel()
        XCTAssertTrue(canceled)
    }
}

// MARK: - Private Helpers
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension CreateTests {
    func makePublisher(fail: Bool = false) -> AnyPublisher<String, MyError> {
        AnyPublisher<String, MyError>.create { subscriber in
            self.allValues.forEach { subscriber.send($0) }
            subscriber.send(completion: fail ? .failure(MyError.failure) : .finished)

            return AnyCancellable { [weak self] in
                self?.canceled = true
            }
        }
        .eraseToAnyPublisher()
    }
    
    func makeSubscriber(demand: Subscribers.Demand) -> AnySubscriber<String, MyError> {
        return AnySubscriber(
            receiveSubscription: { subscription in
                XCTAssertEqual("\(subscription)", "Create.Subscription<String, MyError>")
                subscription.request(demand)
            },
            receiveValue: { value in
                self.values.append(value)
                return .none
            },
            receiveCompletion: { finished in
                self.completion = finished
            })
    }
}
#endif
