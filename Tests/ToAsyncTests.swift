//
//  ToAsyncTests.swift
//  CombineExtTests
//
//  Created by Thibault Wittemberg on 2021-06-15.
//  Copyright © 2021 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
final class ToAsyncTests: XCTestCase {
    func testToAsync_returns_value_when_future_doesnt_fail() async {
        let expectedValue = Int.random(in: 0...100)

        // Given: a future that emits a value
        let sut = Future<Int, Never> { promise in
            promise(.success(expectedValue))
        }

        // When: awaiting for that future
        let receivedValue = await sut.toAsync()

        // Then: the value is returned
        XCTAssertEqual(receivedValue, expectedValue)
    }

    func testToAsync_throws_error_when_future_fails() async {
        struct MockError: Error, Equatable {
            let value: Int
        }

        let expectedError = MockError(value: Int.random(in: 0...100))

        // Given: a Future that fails
        let sut = Future<Int, MockError> { promise in
            promise(.failure(expectedError))
        }

        do {
            // When: awaiting for that future
            _ = try await sut.toAsync()
        } catch {
            // Then: the async function throws the expected error
            XCTAssertEqual(error as? MockError, expectedError)
        }
    }
}
#endif
