//
//  WeakAssignTests.swift
//  CombineExtTests
//
//  Created by Apostolos Giokas on 07/06/2020
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class WeakAssignTests: XCTestCase {

    func testWeakAssign() {
        var someObject: SomeObj? = SomeObj()

        XCTAssertEqual(SomeObj.referenceCount, 1)
        XCTAssertEqual(someObject?.value, 10)

        someObject?.subject.send(12)
        XCTAssertEqual(someObject?.value, 24)

        someObject = nil
        XCTAssertEqual(SomeObj.referenceCount, 0)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private class SomeObj {
    static var referenceCount: Int = 0
    private var cancelable = [AnyCancellable]()
    let subject = CurrentValueSubject<Int, Never>(5)
    private(set) var value: Int = 0

    init() {
        SomeObj.referenceCount += 1
        subject.map { $0 * 2 }
            .weakAssign(to: \.value, on: self).store(in: &cancelable)
    }
    deinit {
        SomeObj.referenceCount -= 1
    }
}
#endif
