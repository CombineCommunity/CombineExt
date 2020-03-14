//
//  FlatMapLatestTests.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 13/03/2020.
//

import XCTest
import Combine
import CombineExt

class FlatMapLatestTests: XCTestCase {
    var subscription: AnyCancellable!

    private func publish() -> AnyPublisher<String, Never> {
        Timer
            .publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .map { _ in UUID().uuidString }
            .prefix(2)
            .eraseToAnyPublisher()
    }
    
    func testInnerOnly() {
        let trigger = PassthroughSubject<Void, Never>()
        var subscriptions = 0
        var values = 0
        var cancellations = 0
        var completed = false
        
        let waiter = XCTWaiter()
        let expect = expectation(description: "")
        
        subscription = trigger
            .flatMapLatest { _ -> AnyPublisher<String, Never> in
                return self.publish()
                    .handleEvents(receiveSubscription: { _ in subscriptions += 1 },
                                  receiveCancel: { cancellations += 1 })
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { _ in
                    completed = true
                    expect.fulfill()
                  },
                  receiveValue: { _ in values += 1 })
            
        trigger.send()
        trigger.send()
        trigger.send()
        trigger.send()
        
        waiter.wait(for: [expect], timeout: 5.0)
        XCTAssertEqual(subscriptions, 4)
        XCTAssertEqual(cancellations, 3)
        XCTAssertEqual(values, 2)

        // There is a known bug in Xcode 11.3 and below where an inner
        // completion doesn't complete the outer publisher, so this test
        // will only work after Xcode 11.4.
        // See: https://forums.swift.org/t/confused-about-behaviour-of-switchtolatest-in-combine/29914/24
        // XCTAssertTrue(completed)
    }
}
