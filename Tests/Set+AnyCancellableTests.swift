//
//  Set+AnyCancellableTests.swift
//  CombineExtPackageTests
//
//  Created by Jasdev Singh on 4/10/20.
//

import Combine
import CombineExt
import XCTest

final class SetAnyCancellableTests: XCTestCase {
    func testStorageSequenceVariant() {
        var subscriptions = Set<AnyCancellable>()

        subscriptions.store(
            (1...3).map {
                Just($0)
                    .sink(receiveValue: { _ in })
            }
        )

        XCTAssertEqual(subscriptions.count, 3)

        subscriptions.removeAll()

        XCTAssertTrue(subscriptions.isEmpty)

        subscriptions.store([])

        XCTAssertTrue(subscriptions.isEmpty)
    }

    func testStorageVariadicVariant() {
        var subscriptions = Set<AnyCancellable>()

        subscriptions.store(
            Just(1)
                .sink(receiveValue: { _ in }),
            Just(2)
                .sink(receiveValue: { _ in }),
            Just(3)
                .sink(receiveValue: { _ in })
        )

        XCTAssertEqual(subscriptions.count, 3)

        subscriptions.removeAll()

        XCTAssertTrue(subscriptions.isEmpty)
    }
}
