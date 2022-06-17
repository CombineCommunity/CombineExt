//
//  FlatMapLatestTests.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 13/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt
import CombineSchedulers

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class FlatMapLatestTests: XCTestCase {
    var subscription: AnyCancellable!
    
    func testInnerOnly() {
        let trigger = PassthroughSubject<Void, Never>()
        var subscriptions = 0
        var values = 0
        var cancellations = 0
        var completed = false
        let scheduler = DispatchQueue.test
        
        func publish() -> AnyPublisher<String, Never> {
            Publishers.Timer(every: 0.5, scheduler: scheduler)
                .autoconnect()
                .map { _ in UUID().uuidString }
                .prefix(2)
                .eraseToAnyPublisher()
        }
        
        subscription = trigger
            .flatMapLatest { _ -> AnyPublisher<String, Never> in
                return publish()
                    .handleEvents(receiveSubscription: { _ in subscriptions += 1 },
                                  receiveCancel: { cancellations += 1 })
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { _ in
                    completed = true
                  },
                  receiveValue: { _ in values += 1 })
            
        trigger.send()
        trigger.send()
        trigger.send()
        trigger.send()

        scheduler.advance(by: 5)

        XCTAssertEqual(subscriptions, 4)
        XCTAssertEqual(cancellations, 3)
        XCTAssertEqual(values, 2)

        // There is a known bug in Xcode 11.3 and below where an inner
        // completion doesn't complete the outer publisher, so this test
        // will only work after Xcode 11.4 and iOS/tvOS 13.4 or macOS 10.15.4.
        // See: https://forums.swift.org/t/confused-about-behaviour-of-switchtolatest-in-combine/29914/24
        // XCTAssertTrue(completed)
        _ = completed
    }
}
#endif
