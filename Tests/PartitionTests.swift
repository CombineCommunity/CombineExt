//
//  WithLatestFrom.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 24/10/2019.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import XCTest
import Combine
import CombineExt

class PartitionTests: XCTestCase {
    var source = PassthroughRelay<Int>()
    var evenSub: AnyCancellable!
    var oddSub: AnyCancellable!

    override func setUp() {
        source = .init()
        evenSub = nil
        oddSub = nil
    }

    func testPartitionBothMatch() {
        let (evens, odds) = source.partition { $0 % 2 == 0 }
        var evenValues = [Int]()
        var oddValues = [Int]()

        evenSub = evens
            .sink(receiveValue: { evenValues.append($0) })

        oddSub = odds
            .sink(receiveValue: { oddValues.append($0) })

        (0...10).forEach { source.accept($0) }

        XCTAssertEqual([1, 3, 5, 7, 9], oddValues)
        XCTAssertEqual([0, 2, 4, 6, 8, 10], evenValues)
    }

    func testPartitionOneSideMatch() {
        let (all, none) = source.partition { $0 <= 10 }
        var allValues = [Int]()
        var noneValues = [Int]()

        evenSub = all
            .sink(receiveValue: { allValues.append($0) })

        oddSub = none
            .sink(receiveValue: { noneValues.append($0) })

        (0...10).forEach { source.accept($0) }

        XCTAssertEqual([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], allValues)
        XCTAssertTrue(noneValues.isEmpty)
    }
}
