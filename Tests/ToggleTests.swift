//
//  ToggleTests.swift
//  CombineExt
//
//  Created by Keita Watanabe on 06/06/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class ToggleTests: XCTestCase {
    func testSomeInitialization() {
        var results = [Bool]()
        _ = [true, false, true, false, true].publisher
            .toggle()
            .sink { results.append($0) }

        XCTAssertEqual([false, true, false, true, false], results)
    }
}
#endif
