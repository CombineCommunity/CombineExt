//
//  CreateTests.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 14/03/2020.
//  Copyright © 2019 Combine Community. All rights reserved.
//

import XCTest
import Combine
import CombineExt

class CreateTests: XCTestCase {
    var subscription: AnyCancellable!
    enum MyError: Swift.Error {
        case failure
    }
    
    private var completion: Subscribers.Completion<CreateTests.MyError>?
    private var values = [String]()
    private let allValues = ["Hello", "World", "What's", "Up?"]
    
    override func setUp() {
        values = []
        completion = nil
    }
    
    func testUnlimitedDemandFinished() {
        let expect = expectation(description: "6 values and finished event")
        let subscriber = makeSubscriber(demand: .unlimited,
                                        expectation: expect)
        let publisher = makePublisher(fail: false)

        publisher.subscribe(subscriber)
        wait(for: [expect], timeout: 1)
        
        XCTAssertEqual(completion, .finished)
        XCTAssertEqual(values, allValues)
    }

    func testLimitedDemandFinished() {
        let expect = expectation(description: "2 values and finished event")
        let subscriber = makeSubscriber(demand: .max(2),
                                        expectation: expect)
        let publisher = makePublisher(fail: false)
        
        publisher.subscribe(subscriber)
        wait(for: [expect], timeout: 1)
        
        XCTAssertEqual(completion, .finished)
        XCTAssertEqual(values, Array(allValues.prefix(2)))
    }
    
    func testNoDemandFinished() {
        let expect = expectation(description: "no values and finished event")
        let subscriber = makeSubscriber(demand: .none,
                                        expectation: expect)
        let publisher = makePublisher(fail: false)
        
        publisher.subscribe(subscriber)
        wait(for: [expect], timeout: 1)
        
        XCTAssertEqual(completion, .finished)
        XCTAssertTrue(values.isEmpty)
    }
    
    func testUnlimitedDemandError() {
        let expect = expectation(description: "6 values and error event")
        let subscriber = makeSubscriber(demand: .unlimited,
                                        expectation: expect)
        let publisher = makePublisher(fail: true)

        publisher.subscribe(subscriber)
        wait(for: [expect], timeout: 1)
        
        XCTAssertEqual(completion, .failure(MyError.failure))
        XCTAssertEqual(values, allValues)
    }

    func testLimitedDemandError() {
        let expect = expectation(description: "2 values and error event")
        let subscriber = makeSubscriber(demand: .max(2),
                                        expectation: expect)
        let publisher = makePublisher(fail: true)
        
        publisher.subscribe(subscriber)
        wait(for: [expect], timeout: 1)
        
        XCTAssertEqual(completion, .failure(MyError.failure))
        XCTAssertEqual(values, Array(allValues.prefix(2)))
    }
    
    func testNoDemandError() {
        let expect = expectation(description: "no values and error event")
        let subscriber = makeSubscriber(demand: .none,
                                        expectation: expect)
        let publisher = makePublisher(fail: true)
        
        publisher.subscribe(subscriber)
        wait(for: [expect], timeout: 1)
        
        XCTAssertEqual(completion, .failure(MyError.failure))
        XCTAssertTrue(values.isEmpty)
    }
}

// MARK: - Private Helpers
private extension CreateTests {
    func makePublisher(fail: Bool = false) -> AnyPublisher<String, MyError> {
        AnyPublisher<String, MyError>.create { subscriber in
            self.allValues.forEach { subscriber(.value($0)) }
            fail ? subscriber(.failure(MyError.failure)) : subscriber(.finished)
        }
    }
    
    func makeSubscriber(demand: Subscribers.Demand, expectation: XCTestExpectation?) -> AnySubscriber<String, MyError> {
        return AnySubscriber(
            receiveSubscription: { subscription in
                subscription.request(demand)
            },
            receiveValue: { value in
                self.values.append(value)
                return .none
            },
            receiveCompletion: { finished in
                self.completion = finished
                expectation?.fulfill()
            })
    }
}
