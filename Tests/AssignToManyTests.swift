//
//  AssignToManyTests.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 13/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class AssignToManyTests: XCTestCase {
    var subscription: AnyCancellable!

    func testAssignToOne() {
        let source = PassthroughSubject<Int, Never>()

        for ownership in [ObjectOwnership.strong, .weak, .unowned] {
            let dest1 = Fake1(prop: 0)

            XCTAssertEqual(dest1.prop, 0)

            subscription = source
                .assign(to: \.prop, on: dest1, ownership: ownership)

            source.send(4)
            XCTAssertEqual(dest1.prop, 4, "\(ownership) ownership")

            source.send(12)
            XCTAssertEqual(dest1.prop, 12, "\(ownership) ownership")

            source.send(-7)
            XCTAssertEqual(dest1.prop, -7, "\(ownership) ownership")
        }
    }

    func testAssignToTwo() {
        let source = PassthroughSubject<Int, Never>()

        for ownership in [ObjectOwnership.strong, .weak, .unowned] {
            let dest1 = Fake1(prop: 0)
            let dest2 = Fake2(ivar: 0)

            XCTAssertEqual(dest1.prop, 0)
            XCTAssertEqual(dest2.ivar, 0)

            subscription = source
                .assign(to: \.prop, on: dest1,
                        and: \.ivar, on: dest2,
                        ownership: ownership)

            source.send(4)
            XCTAssertEqual(dest1.prop, 4, "\(ownership) ownership")
            XCTAssertEqual(dest2.ivar, 4, "\(ownership) ownership")

            source.send(12)
            XCTAssertEqual(dest1.prop, 12, "\(ownership) ownership")
            XCTAssertEqual(dest2.ivar, 12, "\(ownership) ownership")

            source.send(-7)
            XCTAssertEqual(dest1.prop, -7, "\(ownership) ownership")
            XCTAssertEqual(dest2.ivar, -7, "\(ownership) ownership")
        }
    }
    
    func testAssignToThree() {
        let source = PassthroughSubject<String, Never>()

        for ownership in [ObjectOwnership.strong, .weak, .unowned] {
            let dest1 = Fake1(prop: "")
            let dest2 = Fake2(ivar: "")
            let dest3 = Fake3(value: "") { String(repeating: $0, count: $0.count) }

            XCTAssertEqual(dest1.prop, "")
            XCTAssertEqual(dest2.ivar, "")
            XCTAssertEqual(dest3.value, "")

            subscription = source
                .assign(to: \.prop, on: dest1,
                        and: \.ivar, on: dest2,
                        and: \.value, on: dest3,
                        ownership: ownership)

            source.send("Hello")
            XCTAssertEqual(dest1.prop, "Hello", "\(ownership) ownership")
            XCTAssertEqual(dest2.ivar, "Hello", "\(ownership) ownership")
            XCTAssertEqual(dest3.value, "HelloHelloHelloHelloHello", "\(ownership) ownership")

            source.send("Meh")
            XCTAssertEqual(dest1.prop, "Meh", "\(ownership) ownership")
            XCTAssertEqual(dest2.ivar, "Meh", "\(ownership) ownership")
            XCTAssertEqual(dest3.value, "MehMehMeh", "\(ownership) ownership")
        }
    }
}

// MARK: - Private Helpers
private class Fake1<T> {
    var prop: T
    
    init(prop: T) {
        self.prop = prop
    }
}

private class Fake2<T> {
    var ivar: T
    
    init(ivar: T) {
        self.ivar = ivar
    }
}

private class Fake3<T> {
    var value: T {
        set { storage = transform(newValue) }
        get { storage }
    }
    
    var storage: T
    var transform: (T) -> T
    
    init(value: T, transform: @escaping (T) -> T) {
        self.storage = transform(value)
        self.transform = transform
    }
}
#endif
