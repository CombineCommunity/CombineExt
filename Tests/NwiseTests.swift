//
//  CurrentValueRelayTests.swift
//  CombineExtTests
//
//  Created by Bas van Kuijck on 14/08/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class NwiseTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testNwise() {
        var expectedOutput: [[Int]] = []
        var completion: Subscribers.Completion<Never>?
        
        Publishers.Sequence(sequence: [1, 2, 3, 4, 5, 6])
            .nwise(3)
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { expectedOutput.append($0) }
            ).store(in: &subscriptions)
        
        XCTAssertEqual(
            expectedOutput,
            [
                [1, 2, 3],
                [2, 3, 4],
                [3, 4, 5],
                [4, 5, 6]
            ]
        )
        XCTAssertEqual(completion, .finished)
    }
    
    func testNwiseNone() {
        var completion: Subscribers.Completion<Never>?
        
        Publishers.Sequence(sequence: [1, 2, 3])
            .nwise(4)
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { XCTAssert(false, "Should not receive a value, got \($0)") }
            ).store(in: &subscriptions)
        
        XCTAssertEqual(completion, .finished)
    }
    
    func testPairwise() {
        var expectedOutput: [[Int]] = []
        var completion: Subscribers.Completion<Never>?
        
        Publishers.Sequence(sequence: [1, 2, 3, 4, 5, 6])
            .pairwise()
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { expectedOutput.append([$0.0, $0.1]) }
            ).store(in: &subscriptions)
        
        XCTAssertEqual(
            expectedOutput,
            [
                [1, 2],
                [2, 3],
                [3, 4],
                [4, 5],
                [5, 6],
            ]
        )
        XCTAssertEqual(completion, .finished)
    }
}
#endif
