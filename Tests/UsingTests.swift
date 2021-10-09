//
//  UsingTests.swift
//  CombineExt
//
//  Created by Daniel Tartaglia on 10/9/2021.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class UsingTests: XCTestCase {

    func testComplete() {
        let subject = PassthroughSubject<Int, Never>()
        var subscription: AnyCancellable?
        var completion: Subscribers.Completion<Never>?
        var values = [Int]()
        var didCancel = false
        var didDeinit = false

        let publisher = Publishers.Using(
            {
                MockResource(cancel: { didCancel = true }, deinit: { didDeinit = true })
            },
            publisherFactory: { (resource) in
                subject.eraseToAnyPublisher()
            })

        subscription = publisher
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { values.append($0) }
            )

        subject.send(1)
        subject.send(2)

        XCTAssertEqual(values, [1, 2])
        XCTAssertFalse(didCancel)

        subject.send(completion: .finished)

        XCTAssertEqual(completion, .finished)
        XCTAssertTrue(didCancel)
        XCTAssertTrue(didDeinit)
    }

    func testCancel() {
        let subject = PassthroughSubject<Int, Never>()
        var subscription: AnyCancellable?
        var completion: Subscribers.Completion<Never>?
        var values = [Int]()
        var didCancel = false
        var didDeinit = false

        let publisher = Publishers.Using(
            {
                MockResource(cancel: { didCancel = true }, deinit: { didDeinit = true })
            },
            publisherFactory: { (resource) in
                subject.eraseToAnyPublisher()
            })

        subscription = publisher
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { values.append($0) }
            )

        subject.send(1)
        subject.send(2)

        XCTAssertEqual(values, [1, 2])
        XCTAssertFalse(didCancel)

        subscription = nil

        XCTAssertNil(completion)
        XCTAssertTrue(didCancel)
        XCTAssertTrue(didDeinit)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class MockResource: Cancellable {
    init(cancel: @escaping () -> Void, deinit: @escaping () -> Void) {
        _cancel = cancel
        _deinit = `deinit`
    }
    deinit {
        _deinit()
    }

    func cancel() {
        _cancel()
    }

    let _cancel: () -> Void
    let _deinit: () -> Void
}
#endif
