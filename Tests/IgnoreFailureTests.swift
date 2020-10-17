//
//  IgnoreFailureTests.swift
//  CombineExtTests
//
//  Created by Jasdev Singh on 17/10/20.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt
import CombineSchedulers

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class IgnoreFailureTests: XCTestCase {
    private var cancellable: AnyCancellable!

    func testIgnoreFailure() {
        let publisher = Just("someString")
            .setFailureType(to: Error.self)
            .ignoreFailure() // `Never` out the above failure type.
            .eraseToAnyPublisher()

        XCTAssertTrue(type(of: publisher) == AnyPublisher<String, Never>.self)
    }

    private enum TestError: Error {
        case anError
    }

    func testIgnoreFailureErrorEventCompleteImmediately() {
        let subject = PassthroughSubject<Int, TestError>()

        var values = [Int]()
        var completions = [Subscribers.Completion<Never>]()

        cancellable = subject
            .ignoreFailure()
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { values.append($0) })

        subject.send(1)
        subject.send(2)
        subject.send(3)

        subject.send(completion: .failure(.anError))

        XCTAssertEqual([1, 2, 3], values)
        XCTAssertEqual([.finished], completions)
    }

    func testIgnoreFailureErrorEventNoCompletion() {
        let subject = PassthroughSubject<Int, TestError>()

        var values = [Int]()
        var completions = [Subscribers.Completion<Never>]()

        cancellable = subject
            .ignoreFailure(completeImmediately: false)
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { values.append($0) })

        subject.send(1)
        subject.send(2)
        subject.send(3)

        subject.send(completion: .failure(.anError))

        XCTAssertEqual([1, 2, 3], values)
        XCTAssertTrue(completions.isEmpty)
    }

    private enum AnotherTestError: Error, Equatable {
        case anotherError
    }

    func testIgnoreFailureSetFailureTypeCompleteImmediately() {
        let subject = PassthroughSubject<Int, TestError>()

        var values = [Int]()
        var completions = [Subscribers.Completion<AnotherTestError>]()

        let newPublisher = subject
            .ignoreFailure(setFailureType: AnotherTestError.self)
            .eraseToAnyPublisher()

        XCTAssertTrue(type(of: newPublisher) == AnyPublisher<Int, AnotherTestError>.self)

        cancellable = newPublisher
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { values.append($0) })

        subject.send(1)
        subject.send(2)
        subject.send(3)

        subject.send(completion: .failure(.anError))

        XCTAssertEqual([1, 2, 3], values)
        XCTAssertEqual([.finished], completions)
    }

    func testIgnoreFailureSetFailureTypeNoCompletion() {
        let subject = PassthroughSubject<Int, TestError>()

        var values = [Int]()
        var completions = [Subscribers.Completion<AnotherTestError>]()

        let newPublisher = subject
            .ignoreFailure(setFailureType: AnotherTestError.self, completeImmediately: false)

        cancellable = newPublisher
            .sink(
                receiveCompletion: { completions.append($0) },
                receiveValue: { values.append($0) })

        subject.send(1)
        subject.send(2)
        subject.send(3)

        subject.send(completion: .failure(.anError))

        XCTAssertEqual([1, 2, 3], values)
        XCTAssertTrue(completions.isEmpty)
    }
}
#endif
