//
//  FilterManyTests.swift
//  CombineExtTests
//
//  Created by Hugo Saynac on 30/09/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class FilterManyTests: XCTestCase {
    var subscription: AnyCancellable!
    
    func testFilterManyWithModelAndFinishedCompletion() {
        let source = PassthroughSubject<[Int], Never>()
        
        var expectedOutput = [Int]()
        
        var completion: Subscribers.Completion<Never>?
        
        subscription = source
            .filterMany(isPair)
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { $0.forEach { expectedOutput.append($0) } }
            )
        
        source.send([10, 1, 2, 4, 3, 8])
        source.send(completion: .finished)
        
        XCTAssertEqual(
            expectedOutput,
            [10, 2, 4, 8]
        )
        XCTAssertEqual(completion, .finished)
    }
    
    func testFilterManyWithModelAndFailureCompletion() {
        let source = PassthroughSubject<[Int], FilterManyError>()
        
        var expectedOutput = [Int]()
        
        var completion: Subscribers.Completion<FilterManyError>?
        
        subscription = source
            .filterMany(isPair)
            .sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { $0.forEach { expectedOutput.append($0) } }
            )
        
        source.send([10, 1, 2, 4, 3, 8])
        source.send(completion: .failure(.anErrorCase))
        
        XCTAssertEqual(
            expectedOutput,
            [10, 2, 4, 8]
        )
        XCTAssertEqual(completion, .failure(.anErrorCase))
    }
}

private func isPair(_ value: Int) -> Bool {
    value.isMultiple(of: 2)
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension FilterManyTests {
    enum FilterManyError: Error {
        case anErrorCase
    }
}
#endif
