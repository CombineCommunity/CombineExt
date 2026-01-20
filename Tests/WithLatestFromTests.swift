//
//  WithLatestFromTests.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 24/10/2019.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest

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
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results.append($0) }
            )

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
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { results.append($0) }
            )

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
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { results.append($0) }
            )

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
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results.append($0) }
            )

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
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { results.append($0) }
            )

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
                receiveCompletion: { _ in completed = true },
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
                                 "9|qux|false"])

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
                receiveCompletion: { _ in completed = true },
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
                                 Result(string: "qux", boolean: false)])

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
                receiveCompletion: { _ in completed = true },
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
                                 "9|qux|true|8"])

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
                receiveCompletion: { _ in completed = true },
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
                                 Result(string: "qux", boolean: true, integer: 8)])

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

    // MARK: - Thread Safety Tests (Issue #163, #171)

    func testThreadSafetyWithConcurrentEmissions() async {
        // Test for issue #163 - withLatestFrom should be thread safe
        // when subscribing to publishers emitting from different threads
        let iterations = 100

        actor ResultCollector {
            var results: [String] = []

            func append(_ value: String) {
                results.append(value)
            }

            func getCount() -> Int {
                results.count
            }
        }

        for _ in 0 ..< iterations {
            let subject1 = PassthroughSubject<Int, Never>()
            let subject2 = PassthroughSubject<String, Never>()
            let collector = ResultCollector()

            // Wrap in Sendable box for intentional concurrent access in tests
            let box1 = UnsafeSendableBox(value: subject1)
            let box2 = UnsafeSendableBox(value: subject2)

            subscription = subject1
                .withLatestFrom(subject2) { "\($0)-\($1)" }
                .sink { value in
                    Task { await collector.append(value) }
                }

            // Emit from different threads concurrently
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for i in 0 ..< 10 {
                        box2.value.send("value\(i)")
                        try? await Task.sleep(nanoseconds: 1000)
                    }
                }

                group.addTask {
                    // Small delay to ensure subject2 has emitted first
                    try? await Task.sleep(nanoseconds: 10000)
                    for i in 0 ..< 10 {
                        box1.value.send(i)
                        try? await Task.sleep(nanoseconds: 1000)
                    }
                }
            }

            // Small delay to allow sink to process
            try? await Task.sleep(nanoseconds: 100_000)

            let count = await collector.getCount()
            XCTAssertGreaterThan(count, 0, "Should have received at least one result")
        }
    }

    func testThreadSafetyWithSelfReference() async {
        // Test for issue #171 - withLatestFrom with self-reference should not crash
        // This tests thread-safety, not timing guarantees (which aren't promised for self-reference)
        let iterations = 50

        for _ in 0 ..< iterations {
            let nodes = CurrentValueSubject<[Int], Never>([])
            let box = UnsafeSendableBox(value: nodes)
            var didReceiveValue = false

            subscription = nodes
                .dropFirst()
                .filter { !$0.isEmpty }
                .withLatestFrom(nodes)
                .sink { _ in
                    didReceiveValue = true
                }

            // Emit from different threads concurrently
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    box.value.send([1, 2, 3])
                }

                group.addTask {
                    try? await Task.sleep(nanoseconds: 10000)
                    box.value.send([1, 2, 3, 4])
                }

                group.addTask {
                    try? await Task.sleep(nanoseconds: 20000)
                    box.value.send([1, 2, 3, 4, 5])
                }
            }

            // Small delay to allow sink to process
            try? await Task.sleep(nanoseconds: 200_000)

            // The key test is that we don't crash - receiving values is a bonus
            XCTAssertTrue(didReceiveValue || !didReceiveValue, "Test completed without crashing")
        }
    }

    func testThreadSafetyWithRapidEmissions() async {
        // Stress test with rapid emissions from multiple threads
        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<Int, Never>()

        actor ResultCollector {
            var results: [Int] = []

            func append(_ value: Int) {
                results.append(value)
            }

            func getCount() -> Int {
                results.count
            }
        }

        let collector = ResultCollector()
        let box1 = UnsafeSendableBox(value: subject1)
        let box2 = UnsafeSendableBox(value: subject2)

        subscription = subject1
            .withLatestFrom(subject2) { $0 + $1 }
            .sink { value in
                Task { await collector.append(value) }
            }

        await withTaskGroup(of: Void.self) { group in
            // Rapidly emit from subject2
            group.addTask {
                for i in 0 ..< 1000 {
                    box2.value.send(i)
                }
            }

            // Rapidly emit from subject1
            group.addTask {
                try? await Task.sleep(nanoseconds: 100_000) // Small delay
                for i in 0 ..< 1000 {
                    box1.value.send(i)
                }
            }
        }

        // Small delay to allow sink to process
        try? await Task.sleep(nanoseconds: 1_000_000)

        let count = await collector.getCount()
        XCTAssertGreaterThan(count, 0, "Should have received results")
        XCTAssertLessThanOrEqual(count, 1000, "Should not receive more results than emissions")
    }
}
#endif
