//
//  LiftErrorFromResultTests.swift
//  CombineExtTests
//
//  Created by Yurii Zadoianchuk on 12/03/2021.
//  Copyright © 2021 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class LiftErrorFromResultTests: XCTestCase {
    var subscription: AnyCancellable!

    enum LiftErrorFromResultError: Error {
        case someError
    }

    func testLiftNoError() {
        let subject = PassthroughSubject<Result<Int, LiftErrorFromResultError>, Never>()
        let testInt = 5
        var completion: Subscribers.Completion<LiftErrorFromResultError>? = nil
        var result: Int? = nil

        subscription = subject
            .liftErrorFromResult()
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { result = $0 })

        subject.send(.success(testInt))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, testInt)
        XCTAssertNil(completion)
    }

    func testLiftError() {
        let subject = PassthroughSubject<Result<Int, LiftErrorFromResultError>, Never>()
        let testError = LiftErrorFromResultError.someError
        var completion: Subscribers.Completion<LiftErrorFromResultError>? = nil
        var result: Int? = nil

        subscription = subject
            .liftErrorFromResult()
            .sink(receiveCompletion: { completion = $0 },
                  receiveValue: { result = $0 })

        subject.send(.failure(testError))
        XCTAssertNil(result)
        XCTAssertNotNil(completion)
        XCTAssert(completion! == .failure(testError))
    }

    func testLiftErrorMultipleResults() {
        let subject = PassthroughSubject<Result<Int, LiftErrorFromResultError>, Never>()
        let testInts = [5, 6, 7]
        let testError = LiftErrorFromResultError.someError
        var completions: [Subscribers.Completion<LiftErrorFromResultError>] = []
        var results: [Int] = []

        subscription = subject
            .liftErrorFromResult()
            .sink(receiveCompletion: { completions.append($0) },
                  receiveValue: { results.append($0) })

        subject.send(.success(testInts[0]))
        subject.send(.success(testInts[1]))
        subject.send(.success(testInts[2]))
        subject.send(.failure(testError))

        XCTAssertEqual(testInts, results)
        XCTAssertEqual(completions.count, 1)
        XCTAssertEqual(completions.first!, .failure(testError))
    }
}

#endif
