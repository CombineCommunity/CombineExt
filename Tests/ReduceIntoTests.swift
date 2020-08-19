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
    
    func testReduceInto() {
        let subject = PassthroughSubject<Int, Never>()

        subscription = subject
          .reduce(into: 0) { $0 += $1 }
          .sink(receiveValue: { XCTAssertEqual(15, $0, "Reduce into should only emit the resulting value once") })

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)
        subject.send(5)
    }
    
    func testReduceIntoAsync() {
        let input = oneThousandInts
        let transform = squareTransform
        let publisher = asyncPublisher(with: input, transform: transform)
        let expectedSum = input.reduce(0) {
            $0 + transform($1)
        }
        let exp = expectation(description: "Publisher completes")
        var lastSum = 0
        var count = 0
        subscription = publisher.reduce(into: 0) {
            $0 += $1
        }.sink(receiveCompletion: { result in
            switch result {
            case .failure(let error):
                XCTFail("Publisher failed with error: \(error)")
            case .finished:
                XCTAssert(true, "Publisher finished")
            }
            exp.fulfill()
        }) { value in
            XCTAssert(lastSum != value, "Receieved duplicate event from publisher")
            count += 1
            lastSum = value
        }
        waitForExpectations(timeout: 5)
        XCTAssert(count == 1, "Should only receive one value for reduce into")
        XCTAssert(expectedSum == lastSum)
    }
    
    func testReduceIntoAsyncFailure() {
        let input = oneThousandInts
        let publisher = asyncPublisher(with: input, transform: squareTransformFailingOnMod10)
        let exp = expectation(description: "Publisher completes")
        subscription = publisher.reduce(into: 0) {
            $0 += $1
        }.sink(receiveCompletion: { result in
            switch result {
            case .failure(_):
                XCTAssert(true, "Publisher failed")
            case .finished:
                XCTFail("Publisher failed to fail")
            }
            exp.fulfill()
        }) { value in
            XCTFail("Publisher failed to fail")
        }
        waitForExpectations(timeout: 5)
    }

}
