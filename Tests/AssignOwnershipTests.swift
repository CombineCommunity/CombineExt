//
//  AssignOwnershipTests.swift
//  CombineExt
//
//  Created by Dmitry Kuznetsov on 08/05/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class AssignOwnershipTests: XCTestCase {
    var subscription: AnyCancellable!
    var value = 0
    var subject: PassthroughSubject<Int, Never>!

    override func setUp() {
        super.setUp()

        subscription = nil
        subject = PassthroughSubject<Int, Never>()
        value = 0
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    func testWeakAssign() {
        checkSingleAssign(for: .weak)
    }

    func testStrongAssign() {
        checkSingleAssign(for: .strong)
    }

    func testUnownedAssign() {
        checkSingleAssign(for: .unowned)
    }

    func testWeakRetain() {
        checkRetainValue(for: .weak) { initialRetainCount, resultRetainCount in
            XCTAssertEqual(initialRetainCount, resultRetainCount)
        }
    }

    func testStrongRetain() {
        checkRetainValue(for: .strong) { initialRetainCount, resultRetainCount in
            XCTAssertEqual(initialRetainCount + 1, resultRetainCount)
        }
    }

    func testUnownedRetain() {
        checkRetainValue(for: .unowned) { initialRetainCount, resultRetainCount in
            XCTAssertEqual(initialRetainCount, resultRetainCount)
        }
    }

    private func checkSingleAssign(for ownership: ObjectOwnership) {
        subscription = subject
            .assign(to: \.value, on: self, ownership: ownership)

        let newValue1 = 10
        subject.send(newValue1)
        XCTAssertEqual(value, newValue1)

        let newValue2 = 11
        subject.send(newValue2)
        XCTAssertEqual(value, newValue2)
    }

    private func checkRetainValue(for ownership: ObjectOwnership, completion: (Int, Int) -> Void) {
        let initialRetainCount = CFGetRetainCount(self)

        subscription = subject
            .assign(to: \.value, on: self, ownership: ownership)

        let resultRetainCount = CFGetRetainCount(self)

        completion(initialRetainCount, resultRetainCount)
    }
}
