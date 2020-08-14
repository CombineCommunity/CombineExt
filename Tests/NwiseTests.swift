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

private struct PairwiseTuple<T: Equatable>: Equatable {
    let element1: T
    let element2: T
    
    init(_ tuple: (T, T)) {
        element1 = tuple.0
        element2 = tuple.1
    }
    
    init(_ element1: T, _ element2: T) {
        self.element1 = element1
        self.element2 = element2
    }
    
    static func == (lhs: PairwiseTuple<T>, rhs: PairwiseTuple<T>) -> Bool {
        return lhs.element1 == rhs.element1 && lhs.element2 == rhs.element2
    }
}

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
        var expectedOutput: [PairwiseTuple<Int>] = []
        var completion: Subscribers.Completion<Never>?
        
        Publishers.Sequence(sequence: [1, 2, 3, 4, 5, 6])
            .pairwise()
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { expectedOutput.append(PairwiseTuple($0)) }
            ).store(in: &subscriptions)
        
        XCTAssertEqual(
            expectedOutput,
            [
                PairwiseTuple(1, 2),
                PairwiseTuple(2, 3),
                PairwiseTuple(3, 4),
                PairwiseTuple(4, 5),
                PairwiseTuple(5, 6),
            ]
        )
        XCTAssertEqual(completion, .finished)
    }
    
}
#endif
