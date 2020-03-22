//
//  RetryWhenTests.swift
//  CombineExtTests
//
//  Created by Daniel Tartaglia on 3/21/20.
//

import XCTest
import Combine
import CombineExt

class RetryWhenTests: XCTestCase {
    
    var cancellable: AnyCancellable?
    
    func testNull() {
        let subject1 = PassthroughSubject<Int, Error>()
        var result: Int?
        
        cancellable = subject1
            .retryWhen { $0.mapError { _ in TestFailure(tag: 1) } }
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { value in
                    result = value
                }
            )
        
        subject1.send(1)
        subject1.send(completion: .finished)
        
        XCTAssertEqual(result, 1)
    }
    
    func testErrorFromSource() {
        var passes: Int = 0
        let subject1 = Deferred(createPublisher: { () -> AnyPublisher<Int, Error> in
            if passes == 0 {
                passes += 1
                return Combine.Fail<Int, Error>(error: TestFailure(tag: 1)).eraseToAnyPublisher()
            }
            else {
                return Just(1).mapError { _ in TestFailure(tag: 2) }.eraseToAnyPublisher()
            }
        })
        var result: Int?
        
        cancellable = subject1
            .retryWhen { $0.mapError { _ in TestFailure(tag: 3) } }
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail()
                    }
                },
                receiveValue: { value in
                    result = value
                }
            )
        
        XCTAssertEqual(result, 1)
    }

    func testErrorFromRetry() {
        let subject1 = Combine.Fail<Int, Error>(error: TestFailure(tag: 1))
        var called = false
        cancellable = subject1
            .retryWhen { $0.mapError { _ in TestFailure(tag: 2) }.flatMap { _ in Fail<Int, Error>(error: TestFailure(tag: 3)) } }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail()
                    case .failure(let error):
                        XCTAssertEqual(error as? TestFailure, TestFailure(tag: 3))
                        called = true
                    }
                },
                receiveValue: { value in
                    XCTFail()
                }
            )
        
        XCTAssertEqual(called, true)
    }
    
    func testCompleteFromRetry() {
        let subject1 = Combine.Fail<Int, Error>(error: TestFailure(tag: 1)).eraseToAnyPublisher()
        var called = false
        cancellable = subject1
            .retryWhen { $0.mapError { _ in TestFailure(tag: 2) }.first() }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        called = true
                    case .failure:
                        XCTFail()
                    }
                },
                receiveValue: { value in
                    XCTFail()
                }
            )
        
        XCTAssertEqual(called, true)
    }

}

struct TestFailure: Error, Equatable {
    let tag: Int
}
