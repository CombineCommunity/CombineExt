//
//  MapManyTests.swift
//  CombineExtTests
//
//  Created by Joan Disho on 22/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class MapManyTests: XCTestCase {
    var subscription: AnyCancellable!

    func testMapManyWithModelAndFinishedCompletion() {
        let source = PassthroughSubject<[Int], Never>()

        var expectedOutput = [SomeModel]()

        var completion: Subscribers.Completion<Never>?

        subscription = source
            .mapMany(SomeModel.init)
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { $0.forEach { expectedOutput.append($0) } }
            )

        source.send([10, 2, 2, 4, 3, 8])
        source.send(completion: .finished)

        XCTAssertEqual(
            expectedOutput,
            [
                SomeModel(10),
                SomeModel(2),
                SomeModel(2),
                SomeModel(4),
                SomeModel(3),
                SomeModel(8)
            ]
        )
        XCTAssertEqual(completion, .finished)
    }

    func testMapManyWithModelAndFailureCompletion() {
        let source = PassthroughSubject<[Int], MapManyError>()

        var expectedOutput = [SomeModel]()

        var completion: Subscribers.Completion<MapManyError>?

        subscription = source
            .mapMany(SomeModel.init)
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { $0.forEach { expectedOutput.append($0) } }
            )

        source.send([10, 2, 2, 4, 3, 8])
        source.send(completion: .failure(.anErrorCase))

        XCTAssertEqual(
            expectedOutput,
            [
                SomeModel(10),
                SomeModel(2),
                SomeModel(2),
                SomeModel(4),
                SomeModel(3),
                SomeModel(8)
            ]
        )
        XCTAssertEqual(completion, .failure(.anErrorCase))
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension MapManyTests {
    enum MapManyError: Error {
        case anErrorCase
    }

    struct SomeModel: Equatable, CustomStringConvertible {
        let number: Int
        var description: String { return "#\(number)" }

        init(_ number: Int) {
            self.number = number
        }
    }
}
#endif
