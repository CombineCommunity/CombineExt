//
//  MapToTests.swift
//  CombineExt
//
//  Created by Dan Halliday on 08/05/2022.
//  Copyright © 2022 Combine Community. All rights reserved.
//

import Foundation

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class MapToTests: XCTestCase {
    private var subscription: AnyCancellable!

    func testMapToConstantValue() {
        let subject = PassthroughSubject<Int, Never>()
        var result: Int? = nil

        subscription = subject
            .map(to: 2)
            .sink(receiveValue: { result = $0 })

        subject.send(1)
        XCTAssertEqual(result, 2)
    }
}
#endif
