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
class ScanIntoTests: XCTestCase {
    var subscription: Cancellable?
    
    func testScanInto() {
        let subject = PassthroughSubject<Int, Never>()
        let values = Array(1...5)
        var index = 0
        var sum = 0
        subscription = subject
          .scan(into: 0) { $0 += $1 }
          .sink(receiveValue: {
            guard index < values.endIndex else {
                return
            }
            sum += values[index]
            XCTAssertEqual(sum, $0, "Scan into should emit the correct value")
            index += 1
          })
        values.forEach { subject.send($0) }
        XCTAssertEqual(index, values.endIndex, "Scan into should emit a value for every upstream value")
    }
    
    func testScanIntoAsync() {
        let input = oneThousandInts
        let transform = squareTransform
        let publisher = asyncPublisher(with: input, transform: transform)
        let expectedSum = input.reduce(0) {
            $0 + transform($1)
        }
        let exp = expectation(description: "Publisher completes")
        var lastSum = 0
        var count = 0
        subscription = publisher.scan(into: 0) {
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
        XCTAssert(count == input.count)
        XCTAssert(expectedSum == lastSum)
    }
    
    func testScanIntoAsyncFailure() {
        let input = oneThousandInts
        let publisher = asyncPublisher(with: input, transform: squareTransformFailingOnMod10)
        let expectedSum = input.reduce(0) {
            $0 + squareTransform($1)
        }
        let exp = expectation(description: "Publisher completes")
        var lastSum = 0
        var count = 0
        subscription = publisher.scan(into: 0) {
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
            XCTAssert(lastSum != value, "Receieved duplicate event from publisher")
            count += 1
            lastSum = value
        }
        waitForExpectations(timeout: 5)
        XCTAssert(count != input.count)
        XCTAssert(expectedSum != lastSum)
    }

}
