//
//  CurrentValueRelayTests.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 15/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import XCTest
import Combine
import CombineExt

class CurrentValueRelayTests: XCTestCase {
    private var relay: CurrentValueRelay<String>?
    private var values = [String]()
    private var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        relay = CurrentValueRelay<String>("initial")
        subscriptions = .init()
        values = []
    }

    func testValueGetter() {
        XCTAssertEqual(relay?.value, "initial")
        relay?.accept("second")
        XCTAssertEqual(relay?.value, "second")
        relay?.accept("third")
        XCTAssertEqual(relay?.value, "third")
    }

    func testFinishesOnDeinit() {
        var completed = false

        relay?
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { _ in })
            .store(in: &subscriptions)

        XCTAssertEqual(relay?.value, "initial")

        XCTAssertFalse(completed)
        relay = nil
        XCTAssertTrue(completed)
    }

    func testReplaysCurrentValue() {
        relay?
            .sink(receiveValue: { self.values.append($0) })
            .store(in: &subscriptions)

        XCTAssertEqual(values, ["initial"])

        relay?.accept("yo")
        XCTAssertEqual(values, ["initial", "yo"])

        var secondInitial: String?
        _ = relay?.sink(receiveValue: { secondInitial = $0 })
        XCTAssertEqual(secondInitial, "yo")
    }

    func testSubscribePublisher() {
        var completed = false
        relay?
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { self.values.append($0) })
            .store(in: &subscriptions)

        ["1", "2", "3"]
            .publisher
            .subscribe(relay!)
            .store(in: &subscriptions)

        XCTAssertFalse(completed)
        XCTAssertEqual(values, ["initial", "1", "2", "3"])
    }
}
