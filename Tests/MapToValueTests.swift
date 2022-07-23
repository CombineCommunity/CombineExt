//
//  MapToValueTests.swift
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
final class MapToValueTests: XCTestCase {
    private var subscription: AnyCancellable!

    func testMapToConstantValue() {
        let subject = PassthroughSubject<Int, Never>()
        var result: Int? = nil

        subscription = subject
            .mapToValue(2)
            .sink(receiveValue: { result = $0 })

        subject.send(1)
        XCTAssertEqual(result, 2)
    }

    func testMapToWithMultipleElements() {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3

        let subject = PassthroughSubject<Int, Never>()

        subscription = subject
            .mapToValue("hello")
            .sink { element in
                XCTAssertEqual(element, "hello")
                expectation.fulfill()
            }

        subject.send(1)
        subject.send(2)
        subject.send(1)

        wait(for: [expectation], timeout: 3)
    }

    func testMapToVoidType() {
        let expectation = XCTestExpectation()
        let subject = PassthroughSubject<Int, Never>()

        subscription = subject
            .mapToValue(Void())
            .sink { element in
                XCTAssertTrue(type(of: element) == Void.self)

                expectation.fulfill()
            }

        subject.send(1)

        wait(for: [expectation], timeout: 3)
    }

    func testMapToOptionalType() {
        let subject = PassthroughSubject<Int, Never>()
        let value: String? = nil

        var result: String? = nil

        subscription = subject
            .mapToValue(value)
            .sink(receiveValue: { result = $0 })

        subject.send(1)
        XCTAssertEqual(result, nil)
    }

    /// Checks if regular map functions complies and works as expected.
    func testMapNameCollision() {
        let fooSubject = PassthroughSubject<Int, Never>()
        let barSubject = PassthroughSubject<Int, Never>()

        var result: String? = nil

        let combinedPublisher = Publishers.CombineLatest(fooSubject, barSubject)
            .map { fooItem, barItem in
                fooItem * barItem
            }

        subscription = combinedPublisher
            .map {
                "\($0)"
            }
            .sink(receiveValue: { result = $0 })

        fooSubject.send(5)
        barSubject.send(6)
        XCTAssertEqual(result, "30")
    }

    func testMapToVoidWithMultipleEvents() {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3

        let subject = PassthroughSubject<String, Never>()
        subscription = subject
            .mapToVoid()
            .sink { element in
                XCTAssertTrue(type(of: element) == Void.self)
                expectation.fulfill()
            }

        subject.send("test 1")
        subject.send("test 2")
        subject.send("test 3")

        wait(for: [expectation], timeout: 3)
    }

    func testMapToVoidWithError() {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3

        enum TestError: Error {
            case example
        }

        let subject = PassthroughSubject<String, Error>()
        subscription = subject
            .mapToVoid()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail()
                default:
                    break
                }
            }, receiveValue: {
                expectation.fulfill()
            })

        subject.send("test 1")
        subject.send("test 2")
        subject.send("test 3")
        subject.send(completion: .failure(TestError.example))

        wait(for: [expectation], timeout: 3)
    }
}
#endif
