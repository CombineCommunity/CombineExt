//
//  AnyPublisherTests.swift
//  CombineExt
//
//  Created by Prince Ugwuh on 3/30/20.
//

import XCTest
import Combine

class AnyPublisherTests: XCTestCase {
    var subscription: AnyCancellable!
    
    func testEmpty() {
        var completion: Subscribers.Completion<Never>?

        subscription = AnyPublisher<Void, Never>.empty()
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { _ in }
            )

        XCTAssertEqual(completion, .finished)
    }
    
    func testFail() {
        var completion: Subscribers.Completion<TestFailureCondition>?

        subscription = AnyPublisher<String, TestFailureCondition>.fail(TestFailureCondition.exampleFailure)
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { _ in }
            )

        XCTAssertEqual(completion, .failure(TestFailureCondition.exampleFailure))
    }
    
    func testFailAltInitializer() {
        var completion: Subscribers.Completion<TestFailureCondition>?
        
        subscription = AnyPublisher.fail(outputType: String.self, failure: TestFailureCondition.exampleFailure)
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { _ in }
            )

        XCTAssertEqual(completion, .failure(TestFailureCondition.exampleFailure))
    }
    
    func testJust() {
        var completion: Subscribers.Completion<Never>?
        var completedValue = 0
        
        let initialValue = 10
        
        subscription = AnyPublisher<Int, Never>.just(initialValue)
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { completedValue = $0 }
            )

        XCTAssertEqual(completion, .finished)
        XCTAssertEqual(completedValue, initialValue)
    }
    
    func testDeferred() {
        var completion: Subscribers.Completion<Never>?
        var outputValue = false


        let sut = AnyPublisher<String, Never>.deferred {
            return Just(true)
        }
        
        subscription = sut.sink(receiveCompletion: { completion = $0 },
              receiveValue: { outputValue = $0 })
        
        XCTAssertEqual(completion, .finished)
        XCTAssertTrue(outputValue)
    }
    
    
    func testFuture() {
        let expectation = XCTestExpectation(description: self.debugDescription)
        var completion: Subscribers.Completion<TestFailureCondition>?
        var outputValue = false

        let sut = AnyPublisher<Bool, TestFailureCondition>.future { promise in
            self.asyncAPICall(sabotage: false) { (grantedAccess, err) in
                if let err = err {
                    promise(.failure(err))
                } else {
                    promise(.success(grantedAccess))
                }
            }
        }
        
        subscription = sut.sink(
                receiveCompletion: { completion = $0 ; expectation.fulfill() },
                receiveValue: { outputValue = $0 }
            )
    
        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(completion, .finished)
        XCTAssertTrue(outputValue)
    }
    
    func testFutureFailure() {
        let expectation = XCTestExpectation(description: self.debugDescription)
        var completion: Subscribers.Completion<TestFailureCondition>?
        var outputValue = false

        let sut = AnyPublisher<Bool, TestFailureCondition>.future { promise in
            self.asyncAPICall(sabotage: true) { (grantedAccess, err) in
                if let err = err {
                    promise(.failure(err))
                } else {
                    promise(.success(grantedAccess))
                }
            }
        }
        
        subscription = sut.sink(
                receiveCompletion: { completion = $0 ; expectation.fulfill() },
                receiveValue: { outputValue = $0 }
            )
    
        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(completion, .failure(TestFailureCondition.exampleFailure))
        XCTAssertFalse(outputValue)
    }
}

extension AnyPublisherTests {
    enum TestFailureCondition: Error {
        case exampleFailure
    }
    
    // example of a asynchronous function to be called from within a Future and its completion closure
    func asyncAPICall(sabotage: Bool, completion completionBlock: @escaping ((Bool, TestFailureCondition?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let delay = Int.random(in: 1...3)
            print(" * making async call (delay of \(delay) seconds)")
            sleep(UInt32(delay))
            if sabotage {
                completionBlock(false, TestFailureCondition.exampleFailure)
            }
            completionBlock(true, nil)
        }
    }
}
