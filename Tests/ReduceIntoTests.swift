//
//  ScanIntoTests.swift
//  CombineExtTests
//
//  Created by Joe Walsh on 8/19/20.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import XCTest
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class ReduceIntoTests: XCTestCase {
    var subscription: Cancellable?
    
    enum ReduceIntoTestError: Error {
        case generic
    }
    
    func testReduceInto() {
        let subject = PassthroughSubject<Int, Never>()
        
        subscription = subject
            .reduce(into: 0) { $0 += $1 }
            .sink(receiveValue: {
                XCTAssertEqual(15, $0, "Reduce into should only emit the resulting value once")
            })
        
        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)
        subject.send(5)
        subject.send(completion: .finished)
    }
    
    func testTryReduceInto() {
        let subject = PassthroughSubject<Int, ReduceIntoTestError>()
        
        subscription = subject
            .tryReduce(into: 0, { (sum, val) in
                guard val < 3 else {
                    throw ReduceIntoTestError.generic
                }
                sum += val
            })
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTAssertEqual(error as? ReduceIntoTestError, .generic, "Reduce into error should match the thrown error")
                case .finished:
                    XCTFail("Reduce into shouldn't finish if an error is thrown")
                }
            }, receiveValue: { _ in
                XCTFail("Reduce into shouldn't receive value if subject is never completed")
            })
        
        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)
        subject.send(5)
        subject.send(completion: .finished)
    }
}
