//
//  MapToResultTests.swift
//  CombineExt
//
//  Created by Yurii Zadoianchuk on 05/03/2021.
//  Copyright © 2021 Combine Community. All rights reserved.
//

import Foundation

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class MapToResultTests: XCTestCase {
    private var subscription: AnyCancellable!

    enum MapToResultError: Error {
        case someError
    }

    func testMapResultNoError() {
        let subject = PassthroughSubject<Int, Error>()
        let testInt = 5
        var completed = false
        var results: [Result<Int, Error>] = []

        subscription = subject
            .mapToResult()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { results.append($0) })

        subject.send(testInt)
        XCTAssertFalse(completed)
        subject.send(testInt)
        subject.send(completion: .finished)
        XCTAssertTrue(completed)
        XCTAssertEqual(results.count, 2)
        let intsCorrect = results
            .compactMap { try? $0.get() }
            .allSatisfy { $0 == testInt }
        XCTAssertTrue(intsCorrect)
    }

    func testMapCustomError() {
        let subject = PassthroughSubject<Int, Error>()
        var completed = false
        var gotFailure = false
        var gotSuccess = false
        var result: Result<Int, Error>? = nil

        subscription = subject
            .tryMap { _ -> Int in throw MapToResultError.someError }
            .mapToResult()
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { result = $0 })

        subject.send(0)
        XCTAssertNotNil(result)

        do {
            _ = try result!.get()
            gotSuccess = true
        } catch {
            gotFailure = true
        }

        XCTAssertTrue(gotFailure)
        XCTAssertFalse(gotSuccess)
        XCTAssertTrue(completed)
    }

    func testCatchDecodeError() {
        struct ToDecode: Decodable {
            let foo: Int
        }

        let incorrectJson = """
            {
                "foo": "1"
            }
        """

        let subject = PassthroughSubject<Data, Error>()
        var completed = false
        var gotFailure = false
        var gotSuccess = false
        var result: Result<ToDecode, Error>? = nil

        subscription = subject
            .decode(type: ToDecode.self, decoder: JSONDecoder())
            .mapToResult()
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { result = $0 })

        subject.send(incorrectJson.data(using: .utf8)!)
        XCTAssertNotNil(result)

        do {
            _ = try result!.get()
            gotSuccess = true
        } catch let e {
            XCTAssert(e is DecodingError)
            gotFailure = true
        }

        XCTAssertTrue(gotFailure)
        XCTAssertFalse(gotSuccess)
        XCTAssertTrue(completed)
    }

    func testMapEncodeError() {
        struct ToEncode: Encodable {
            let foo: Int

            func encode(to encoder: Encoder) throws {
                throw EncodingError.invalidValue((), EncodingError.Context(codingPath: [], debugDescription: String()))
            }
        }

        let subject = PassthroughSubject<ToEncode, Error>()
        var completed = false
        var gotFailure = false
        var gotSuccess = false
        var result: Result<Data, Error>? = nil

        subscription = subject
            .encode(encoder: JSONEncoder())
            .mapToResult()
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { result = $0 })

        subject.send(ToEncode(foo: 0))
        XCTAssertNotNil(result)

        do {
            _ = try result!.get()
            gotSuccess = true
        } catch let e {
            XCTAssert(e is EncodingError)
            gotFailure = true
        }

        XCTAssertTrue(gotFailure)
        XCTAssertFalse(gotSuccess)
        XCTAssertTrue(completed)
    }
}

#endif
