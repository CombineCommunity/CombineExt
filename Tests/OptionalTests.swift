//
//  OptionalTests.swift
//  CombineExt
//
//  Created by Jasdev Singh on 11/05/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class OptionalTests: XCTestCase {
    private var subscription: AnyCancellable!

    func testSomeInitialization() {
        var results = [Int]()
        var completion: Subscribers.Completion<Never>?

        subscription = Optional(1)
            .publisher
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { results.append($0) })

        XCTAssertEqual([1], results)
        XCTAssertEqual(.finished, completion)
    }

    func testNoneInitialization() {
        var results = [Int]()
        var completion: Subscribers.Completion<Never>?

        subscription = Optional<Int>.none
            .publisher
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { results.append($0) })

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(.finished, completion)
    }
}
#endif
