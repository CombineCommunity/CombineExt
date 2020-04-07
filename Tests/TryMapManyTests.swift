//
//  TryMapManyTests.swift
//  CombineExtTests
//
//  Created by Joan Disho on 07.04.20.
//

import XCTest
import Combine

class TryMapManyTests: XCTestCase {
    var subscription: AnyCancellable!

    func testTryMapManyWithModelAndFinishedCompletion() {
        let source = PassthroughSubject<[Int], NumberError>()

        var expectedOutput = [SomeModel]()

        var completion: Subscribers.Completion<NumberError>?

        subscription = source
            .tryMapMany { number in
                if number < 5 {
                    throw NumberError.numberSmallerThanFive
                }
                return SomeModel(number)
            }
            .mapError { _ in NumberError.numberSmallerThanFive }
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { $0.forEach { expectedOutput.append($0) } }
            )

        source.send([10, 20, 20, 40, 30, 8])
        source.send(completion: .finished)
        
        XCTAssertEqual(
            expectedOutput,
            [
                SomeModel(10),
                SomeModel(20),
                SomeModel(20),
                SomeModel(40),
                SomeModel(30),
                SomeModel(8)
            ]
        )
        XCTAssertEqual(completion, .finished)
    }

    func testTryMapManyWithModelAndFailureCompletion() {
        let source = PassthroughSubject<[Int], NumberError>()

        var expectedOutput = [SomeModel]()

        var completion: Subscribers.Completion<NumberError>?

        subscription = source
            .tryMapMany { number in
                if number < 5 {
                    throw NumberError.numberSmallerThanFive
                }
                return SomeModel(number)
            }
            .mapError { _ in NumberError.numberSmallerThanFive }
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { $0.forEach { expectedOutput.append($0) } }
            )

        source.send([10, 2, 2, 4, 3, 8])

        XCTAssertEqual(expectedOutput, [])
        XCTAssertEqual(completion, .failure(.numberSmallerThanFive))
    }
}

private extension TryMapManyTests {
    enum NumberError: Error {
        case numberSmallerThanFive
    }

    struct SomeModel: Equatable, CustomStringConvertible {
        let number: Int
        var description: String { return "#\(number)" }

        init(_ number: Int) {
            self.number = number
        }
    }
}
