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
}
