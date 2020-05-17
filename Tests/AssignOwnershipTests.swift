//
//  AssignOwnershipTests.swift
//  CombineExt
//
//  Created by Dmitry Kuznetsov on 08/05/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class AssignOwnershipTests: XCTestCase {
    var subscription: AnyCancellable!
    var value1 = 0
    var value2 = 0
    var value3 = 0
    var subject: PassthroughSubject<Int, Never>!

    override func setUp() {
        super.setUp()

        subscription = nil
        subject = PassthroughSubject<Int, Never>()
        value1 = 0
        value2 = 0
        value3 = 0
    }

    func testWeakOwnership() {
        let initialRetainCount = CFGetRetainCount(self)

        subscription = subject
            .assign(to: \.value1, on: self, ownership: .weak)
        subject.send(10)
        let resultRetainCount1 = CFGetRetainCount(self)
        XCTAssertEqual(initialRetainCount, resultRetainCount1)

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, ownership: .weak)
        subject.send(15)
        let resultRetainCount2 = CFGetRetainCount(self)
        XCTAssertEqual(initialRetainCount, resultRetainCount2)

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, and: \.value3, on: self, ownership: .weak)
        subject.send(20)
        let resultRetainCount3 = CFGetRetainCount(self)
        XCTAssertEqual(initialRetainCount, resultRetainCount3)
    }

    func testUnownedOwnership() {
        let initialRetainCount = CFGetRetainCount(self)

        subscription = subject
            .assign(to: \.value1, on: self, ownership: .unowned)
        subject.send(10)
        let resultRetainCount1 = CFGetRetainCount(self)
        XCTAssertEqual(initialRetainCount, resultRetainCount1)

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, ownership: .unowned)
        subject.send(15)
        let resultRetainCount2 = CFGetRetainCount(self)
        XCTAssertEqual(initialRetainCount, resultRetainCount2)

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, and: \.value3, on: self, ownership: .unowned)
        subject.send(20)
        let resultRetainCount3 = CFGetRetainCount(self)
        XCTAssertEqual(initialRetainCount, resultRetainCount3)
    }

    func testStrongOwnership() {
        let initialRetainCount = CFGetRetainCount(self)

        subscription = subject
            .assign(to: \.value1, on: self, ownership: .strong)
        subject.send(10)
        let resultRetainCount1 = CFGetRetainCount(self)
        XCTAssertEqual(initialRetainCount + 1, resultRetainCount1)

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, ownership: .strong)
        subject.send(15)
        let resultRetainCount2 = CFGetRetainCount(self)
        XCTAssertEqual(initialRetainCount + 2, resultRetainCount2)

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, and: \.value3, on: self, ownership: .strong)
        subject.send(20)
        let resultRetainCount3 = CFGetRetainCount(self)
        XCTAssertEqual(initialRetainCount + 3, resultRetainCount3)
    }
}
#endif
