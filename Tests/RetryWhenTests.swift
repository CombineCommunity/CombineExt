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
            .retryWhen { _ in
                Empty<Void, Error>(completeImmediately: true)
            }
            .sink(
                receiveCompletion: { completion in
                    XCTFail()
                },
                receiveValue: { value in
                    result = value
                }
            )
        
        subject1.send(1)
        
        XCTAssertEqual(result, 1)
    }
    
    func testErrorFromSource() {
        var passes: Int = 0
        let subject1 = Deferred(createPublisher: { () -> AnyPublisher<Int, Error> in
            if passes == 0 {
                passes += 1
                return Combine.Fail<Int, Error>(error: TestFailure()).eraseToAnyPublisher()
            }
            else {
                return Just(1).mapError { _ in TestFailure() }.eraseToAnyPublisher()
            }
        })
        var result: Int?
        
        cancellable = subject1
            .retryWhen { $0.mapError { _ in TestFailure() } }
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
        let subject1 = Combine.Fail<Int, Error>(error: TestFailure()).eraseToAnyPublisher()
        var called = false
        cancellable = subject1
            .retryWhen { _ in Fail<Int, Error>(error: TestFailure()) }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail()
                    case .failure:
                        called = true
                    }
                },
                receiveValue: { value in
                    XCTFail()
                }
            )
        
        XCTAssertEqual(called, true)
    }
}

struct TestFailure: Error { }
