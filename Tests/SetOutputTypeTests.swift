//
//  SetOutputTypeTests.swift
//  CombineExtTests
//
//  Created by Jasdev Singh on 02/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class SetOutputTypeTests: XCTestCase {
    func testSetOutputType() {
        let publisher = Just("someString")
            .ignoreOutput()
            .setOutputType(to: Int.self)
            .eraseToAnyPublisher() // Erasing so the test remains stable
            // across any changes to `Publisher.setOutputType(to:)`’s implementation.

        XCTAssertTrue(type(of: publisher) == AnyPublisher<Int, Never>.self)
    }
}
#endif
