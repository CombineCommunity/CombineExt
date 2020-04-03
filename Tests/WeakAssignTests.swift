//
//  WeakAssignTests.swift
//  CombineExtTests
//
//  Created by Jasdev Singh on 2/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import XCTest
import Combine
import CombineExt

final class WeakAssignTests: XCTestCase {
    private var subscription: AnyCancellable!

    func testWeakAssignment() {
        let source = PassthroughSubject<Int, Never>()
        var destination = Fake(property: 1)

        XCTAssertEqual(destination.property, 1)

        subscription = source
            .assign(to: \.property, on: destination)

        XCTAssertFalse(isKnownUniquelyReferenced(&destination))

        subscription = source
            .weaklyAssign(to: \.property, on: destination)

        XCTAssertTrue(isKnownUniquelyReferenced(&destination))

        source.send(2)
        XCTAssertEqual(destination.property, 2)
    }
}

// MARK: - Private Helpers

private final class Fake<PropertyType> {
    var property: PropertyType

    init(property: PropertyType) {
        self.property = property
    }
}

