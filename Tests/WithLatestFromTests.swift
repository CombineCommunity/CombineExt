//
//  WithLatestFrom.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 24/10/2019.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class WithLatestFromTests: XCTestCase {
    var subscription: AnyCancellable!
    func testWithResultSelector() {
        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<String, Never>()
        var results = [String]()
        var completed = false
        
        subscription = subject1
            .withLatestFrom(subject2) { "\($0)\($1)" }
            .sink(receiveCompletion: { _ in completed  = true },
                  receiveValue: { results.append($0) })
        
        subject1.send(1)
        subject1.send(2)
        subject1.send(3)
        subject2.send("bar")
        subject1.send(4)
        subject1.send(5)
        subject2.send("foo")
        subject1.send(6)
        subject2.send("qux")
        subject1.send(7)
        subject1.send(8)
        subject1.send(9)
        
        XCTAssertEqual(results, ["4bar",
                                 "5bar",
                                 "6foo",
                                 "7qux",
                                 "8qux",
                                 "9qux"])
        
        XCTAssertFalse(completed)
        subject2.send(completion: .finished)
        XCTAssertFalse(completed)
        subject1.send(completion: .finished)
        XCTAssertTrue(completed)
    }
    
    // We have to hold a reference to the subscription or the
    // publisher will get deallocated and canceled
    var demandSubscription: Subscription!
    func testWithResultSelectorLimitedDemand() {
        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<String, Never>()
        var results = [String]()
        var completed = false
        
        let subscriber = AnySubscriber<String, Never>(
            receiveSubscription: { subscription in
                self.demandSubscription = subscription
                subscription.request(.max(3))
            },
            receiveValue: { val in
                results.append(val)
                return .none
            },
            receiveCompletion: { _ in completed = true }
        )
        
        subject1
            .withLatestFrom(subject2) { "\($0)\($1)" }
            .subscribe(subscriber)
        
        subject1.send(1)
        subject1.send(2)
        subject1.send(3)
        subject2.send("bar")
        subject1.send(4)
        subject1.send(5)
        subject2.send("foo")
        subject1.send(6)
        subject2.send("qux")
        subject1.send(7)
        subject1.send(8)
        subject1.send(9)
                
        XCTAssertEqual(results, ["4bar", "5bar", "6foo"])
        
        XCTAssertFalse(completed)
        subject2.send(completion: .finished)
        XCTAssertFalse(completed)
        subject1.send(completion: .finished)
        XCTAssertTrue(completed)
    }
    
    func testWithResultSelectorDoesNotRetainClassBasedPublisher() {
        var subject1: PassthroughSubject<Int, Never>? = PassthroughSubject<Int, Never>()
        var subject2: PassthroughSubject<String, Never>? = PassthroughSubject<String, Never>()
        weak var weakSubject1: PassthroughSubject<Int, Never>? = subject1
        weak var weakSubject2: PassthroughSubject<String, Never>? = subject2
        
        var results = [String]()
        
        subscription = subject1?
            .withLatestFrom(subject2!) { "\($0)\($1)" }
            .sink(receiveCompletion: { _ in },
                  receiveValue: { results.append($0) })
        
        subject1?.send(1)
        subject2?.send("bar")
        subject1?.send(2)
        
        XCTAssertEqual(results, ["2bar"])
        
        subscription = nil
        subject1 = nil
        subject2 = nil
        XCTAssertNil(weakSubject1)
        XCTAssertNil(weakSubject2)
    }
    
    func testWithResultSelectorDoesNotRetainClassBasedPublisherWithoutSendCompletion() {
        var upstream: AnyPublisher? = Just("1")
            .setFailureType(to: Never.self)
            .eraseToAnyPublisher()
        var other: PassthroughSubject<String, Never>? = PassthroughSubject<String, Never>()
        weak var weakOther: PassthroughSubject<String, Never>? = other
        
        var results = [String]()
        
        subscription = upstream?
            .withLatestFrom(other!) { "\($0)\($1)" }
            .sink(receiveCompletion: { _ in },
                  receiveValue: { results.append($0) })
        
        other?.send("foo")
        XCTAssertEqual(results, ["1foo"])
        
        subscription = nil
        upstream = nil
        other = nil
        XCTAssertNil(weakOther)
    }
    
    func testNoResultSelector() {
        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<String, Never>()
        var results = [String]()
        var completed = false
        
        subscription = subject1
          .withLatestFrom(subject2)
            .sink(receiveCompletion: { _ in completed  = true },
                  receiveValue: { results.append($0) })
        
        subject1.send(1)
        subject1.send(2)
        subject1.send(3)
        subject2.send("bar")
        subject1.send(4)
        subject1.send(5)
        subject2.send("foo")
        subject1.send(6)
        subject2.send("qux")
        subject1.send(7)
        subject1.send(8)
        subject1.send(9)
        
        XCTAssertEqual(results, ["bar",
                                 "bar",
                                 "foo",
                                 "qux",
                                 "qux",
                                 "qux"])
        
        XCTAssertFalse(completed)
        subject2.send(completion: .finished)
        XCTAssertFalse(completed)
        subject1.send(completion: .finished)
        XCTAssertTrue(completed)
        subscription.cancel()
    }
    
    func testNoResultSelectorDoesNotRetainClassBasedPublisher() {
        var subject1: PassthroughSubject<Int, Never>? = PassthroughSubject<Int, Never>()
        var subject2: PassthroughSubject<String, Never>? = PassthroughSubject<String, Never>()
        weak var weakSubject1: PassthroughSubject<Int, Never>? = subject1
        weak var weakSubject2: PassthroughSubject<String, Never>? = subject2
        
        var results = [String]()
        
        subscription = subject1?
            .withLatestFrom(subject2!)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { results.append($0) })
        
        subject1?.send(1)
        subject2?.send("bar")
        subject1?.send(4)
        
        XCTAssertEqual(results, ["bar"])
        
        subscription = nil
        subject1 = nil
        subject2 = nil
        XCTAssertNil(weakSubject1)
        XCTAssertNil(weakSubject2)
    }

    func testWithLatestFrom2WithResultSelector() {
        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<String, Never>()
        let subject3 = PassthroughSubject<Bool, Never>()
        var results = [String]()
        var completed = false

        subscription = subject1
          .withLatestFrom(subject2, subject3) { "\($0)|\($1.0)|\($1.1)" }
            .sink(
                receiveCompletion: { _ in completed  = true },
                receiveValue: { results.append($0) }
            )

        subject1.send(1)
        subject1.send(2)
        subject1.send(3)

        subject2.send("bar")

        subject1.send(4)
        subject1.send(5)

        subject3.send(true)

        subject1.send(10)

        subject2.send("foo")

        subject1.send(6)

        subject2.send("qux")

        subject3.send(false)

        subject1.send(7)
        subject1.send(8)
        subject1.send(9)

        XCTAssertEqual(results, ["10|bar|true",
                                 "6|foo|true",
                                 "7|qux|false",
                                 "8|qux|false",
                                 "9|qux|false"
                                ])

        XCTAssertFalse(completed)
        subject2.send(completion: .finished)
        XCTAssertFalse(completed)
        subject3.send(completion: .finished)
        XCTAssertFalse(completed)
        subject1.send(completion: .finished)
        XCTAssertTrue(completed)
    }
    
    func testWithLatestFrom2WithResultSectorDoesNotRetainPublisher() {
        var subject1: PassthroughSubject<Int, Never>? = PassthroughSubject<Int, Never>()
        var subject2: PassthroughSubject<String, Never>? = PassthroughSubject<String, Never>()
        var subject3: PassthroughSubject<Bool, Never>? = PassthroughSubject<Bool, Never>()
        weak var weakSubject1: PassthroughSubject<Int, Never>? = subject1
        weak var weakSubject2: PassthroughSubject<String, Never>? = subject2
        weak var weakSubject3: PassthroughSubject<Bool, Never>? = subject3
        
        var results = [String]()
        
        subscription = subject1?
            .withLatestFrom(subject2!, subject3!) { "\($0)|\($1.0)|\($1.1)" }
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { results.append($0) }
            )
        
        subject2?.send("bar")
        subject3?.send(true)
        subject1?.send(10)
        
        XCTAssertEqual(results, ["10|bar|true"])
        
        subscription = nil
        subject1 = nil
        subject2 = nil
        subject3 = nil
        XCTAssertNil(weakSubject1)
        XCTAssertNil(weakSubject2)
        XCTAssertNil(weakSubject3)
    }

  func testWithLatestFrom2WithNoResultSelector() {

      struct Result: Equatable {
          let string: String
          let boolean: Bool
      }

      let subject1 = PassthroughSubject<Int, Never>()
      let subject2 = PassthroughSubject<String, Never>()
      let subject3 = PassthroughSubject<Bool, Never>()
      var results = [Result]()
      var completed = false

      subscription = subject1
        .withLatestFrom(subject2, subject3)
          .sink(
              receiveCompletion: { _ in completed  = true },
              receiveValue: { results.append(Result(string: $0.0, boolean: $0.1)) }
          )

      subject1.send(1)
      subject1.send(2)
      subject1.send(3)

      subject2.send("bar")

      subject1.send(4)
      subject1.send(5)

      subject3.send(true)

      subject1.send(10)

      subject2.send("foo")

      subject1.send(6)

      subject2.send("qux")

      subject3.send(false)

      subject1.send(7)
      subject1.send(8)
      subject1.send(9)

      XCTAssertEqual(results, [Result(string: "bar", boolean: true),
                               Result(string: "foo", boolean: true),
                               Result(string: "qux", boolean: false),
                               Result(string: "qux", boolean: false),
                               Result(string: "qux", boolean: false)
                              ])

      XCTAssertFalse(completed)
      subject2.send(completion: .finished)
      XCTAssertFalse(completed)
      subject3.send(completion: .finished)
      XCTAssertFalse(completed)
      subject1.send(completion: .finished)
      XCTAssertTrue(completed)
  }
    
    func testWithLatestFrom2WithNoResultSectorDoesNotRetainPublisher() {
        var subject1: PassthroughSubject<Int, Never>? = PassthroughSubject<Int, Never>()
        var subject2: PassthroughSubject<String, Never>? = PassthroughSubject<String, Never>()
        var subject3: PassthroughSubject<Bool, Never>? = PassthroughSubject<Bool, Never>()
        weak var weakSubject1: PassthroughSubject<Int, Never>? = subject1
        weak var weakSubject2: PassthroughSubject<String, Never>? = subject2
        weak var weakSubject3: PassthroughSubject<Bool, Never>? = subject3
        
        var results = [String]()
        
        subscription = subject1?
            .withLatestFrom(subject2!, subject3!)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { results.append("\($0.0)|\($0.1)") }
            )
        
        subject2?.send("bar")
        subject3?.send(true)
        subject1?.send(10)
        
        
        XCTAssertEqual(results, ["bar|true"])
        
        subscription = nil
        subject1 = nil
        subject2 = nil
        subject3 = nil
        XCTAssertNil(weakSubject1)
        XCTAssertNil(weakSubject2)
        XCTAssertNil(weakSubject3)
    }

  func testWithLatestFrom3WithResultSelector() {
      let subject1 = PassthroughSubject<Int, Never>()
      let subject2 = PassthroughSubject<String, Never>()
      let subject3 = PassthroughSubject<Bool, Never>()
      let subject4 = PassthroughSubject<Int, Never>()

      var results = [String]()
      var completed = false

      subscription = subject1
        .withLatestFrom(subject2, subject3, subject4) { "\($0)|\($1.0)|\($1.1)|\($1.2)" }
          .sink(
              receiveCompletion: { _ in completed  = true },
              receiveValue: { results.append($0) }
          )

      subject1.send(1)
      subject1.send(2)
      subject1.send(3)

      subject2.send("bar")

      subject1.send(4)
      subject1.send(5)

      subject3.send(true)
      subject4.send(5)

      subject1.send(10)
      subject4.send(7)

      subject2.send("foo")

      subject1.send(6)

      subject2.send("qux")

      subject3.send(false)

      subject1.send(7)
      subject1.send(8)
      subject4.send(8)
      subject3.send(true)
      subject1.send(9)

     XCTAssertEqual(results, ["10|bar|true|5",
                              "6|foo|true|7",
                              "7|qux|false|7",
                              "8|qux|false|7",
                              "9|qux|true|8"
                              ])

      XCTAssertFalse(completed)
      subject2.send(completion: .finished)
      XCTAssertFalse(completed)
      subject3.send(completion: .finished)
      XCTAssertFalse(completed)
      subject4.send(completion: .finished)
      XCTAssertFalse(completed)
      subject1.send(completion: .finished)
      XCTAssertTrue(completed)
  }
    
    func testWithLatestFrom3WithResultSectorDoesNotRetainPublisher() {
        var subject1: PassthroughSubject<Int, Never>? = PassthroughSubject<Int, Never>()
        var subject2: PassthroughSubject<String, Never>? = PassthroughSubject<String, Never>()
        var subject3: PassthroughSubject<Bool, Never>? = PassthroughSubject<Bool, Never>()
        var subject4: PassthroughSubject<Int, Never>? = PassthroughSubject<Int, Never>()
        weak var weakSubject1: PassthroughSubject<Int, Never>? = subject1
        weak var weakSubject2: PassthroughSubject<String, Never>? = subject2
        weak var weakSubject3: PassthroughSubject<Bool, Never>? = subject3
        weak var weakSubject4: PassthroughSubject<Bool, Never>? = subject3
        
        var results = [String]()
        
        subscription = subject1?
            .withLatestFrom(subject2!, subject3!, subject4!) { "\($0)|\($1.0)|\($1.1)|\($1.2)" }
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { results.append($0) }
            )
        
        subject2?.send("bar")
        subject3?.send(true)
        subject4?.send(100)
        
        subject1?.send(10)
        
        
        XCTAssertEqual(results, ["10|bar|true|100"])
        
        subscription = nil
        subject1 = nil
        subject2 = nil
        subject3 = nil
        subject4 = nil
        XCTAssertNil(weakSubject1)
        XCTAssertNil(weakSubject2)
        XCTAssertNil(weakSubject3)
        XCTAssertNil(weakSubject4)
    }

  func testWithLatestFrom3WithNoResultSelector() {

      struct Result: Equatable {
          let string: String
          let boolean: Bool
          let integer: Int
      }

      let subject1 = PassthroughSubject<Int, Never>()
      let subject2 = PassthroughSubject<String, Never>()
      let subject3 = PassthroughSubject<Bool, Never>()
      let subject4 = PassthroughSubject<Int, Never>()

      var results = [Result]()
      var completed = false

      subscription = subject1
        .withLatestFrom(subject2, subject3, subject4)
          .sink(
              receiveCompletion: { _ in completed  = true },
              receiveValue: { results.append(Result(string: $0.0, boolean: $0.1, integer: $0.2)) }
          )

      subject1.send(1)
      subject1.send(2)
      subject1.send(3)

      subject2.send("bar")

      subject1.send(4)
      subject1.send(5)

      subject3.send(true)
      subject4.send(5)

      subject1.send(10)
      subject4.send(7)

      subject2.send("foo")

      subject1.send(6)

      subject2.send("qux")

      subject3.send(false)

      subject1.send(7)
      subject1.send(8)
      subject4.send(8)
      subject3.send(true)
      subject1.send(9)

    XCTAssertEqual(results, [Result(string: "bar", boolean: true, integer: 5),
                             Result(string: "foo", boolean: true, integer: 7),
                             Result(string: "qux", boolean: false, integer: 7),
                             Result(string: "qux", boolean: false, integer: 7),
                             Result(string: "qux", boolean: true, integer: 8)
                            ])

      XCTAssertFalse(completed)
      subject2.send(completion: .finished)
      XCTAssertFalse(completed)
      subject3.send(completion: .finished)
      XCTAssertFalse(completed)
      subject4.send(completion: .finished)
      XCTAssertFalse(completed)
      subject1.send(completion: .finished)
      XCTAssertTrue(completed)
  }
    
    func testWithLatestFrom3WithNoResultSectorDoesNotRetainPublisher() {
        var subject1: PassthroughSubject<Int, Never>? = PassthroughSubject<Int, Never>()
        var subject2: PassthroughSubject<String, Never>? = PassthroughSubject<String, Never>()
        var subject3: PassthroughSubject<Bool, Never>? = PassthroughSubject<Bool, Never>()
        var subject4: PassthroughSubject<Int, Never>? = PassthroughSubject<Int, Never>()
        weak var weakSubject1: PassthroughSubject<Int, Never>? = subject1
        weak var weakSubject2: PassthroughSubject<String, Never>? = subject2
        weak var weakSubject3: PassthroughSubject<Bool, Never>? = subject3
        weak var weakSubject4: PassthroughSubject<Bool, Never>? = subject3
        
        var results = [String]()
        
        subscription = subject1?
            .withLatestFrom(subject2!, subject3!, subject4!)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { results.append("\($0.0)|\($0.1)|\($0.2)") }
            )
        
        subject2?.send("bar")
        subject3?.send(true)
        subject4?.send(100)
        
        subject1?.send(10)
        
        
        XCTAssertEqual(results, ["bar|true|100"])
        
        subscription = nil
        subject1 = nil
        subject2 = nil
        subject3 = nil
        subject4 = nil
        XCTAssertNil(weakSubject1)
        XCTAssertNil(weakSubject2)
        XCTAssertNil(weakSubject3)
        XCTAssertNil(weakSubject4)
    }
}
#endif
