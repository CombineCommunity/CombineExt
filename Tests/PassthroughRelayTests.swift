//
//  PassthroughRelayTests.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 15/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class PassthroughRelayTests: XCTestCase {
    private var relay: PassthroughRelay<String>?
    private var values = [String]()
    private var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        relay = PassthroughRelay<String>()
        subscriptions = .init()
        values = []
    }

    func testFinishesOnDeinit() {
        var completed = false
        relay?
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { _ in }
            )
            .store(in: &subscriptions)

        XCTAssertFalse(completed)
        relay = nil
        XCTAssertTrue(completed)
    }

    func testNoReplay() {
        relay?.accept("these")
        relay?.accept("values")
        relay?.accept("shouldnt")
        relay?.accept("be")
        relay?.accept("forwaded")

        relay?
            .sink(receiveValue: { self.values.append($0) })
            .store(in: &subscriptions)

        XCTAssertEqual(values, [])

        relay?.accept("yo")
        XCTAssertEqual(values, ["yo"])

        relay?.accept("sup")
        XCTAssertEqual(values, ["yo", "sup"])

        var secondInitial: String?
        _ = relay?.sink(receiveValue: { secondInitial = $0 })
        XCTAssertNil(secondInitial)
    }

    func testVoidAccept() {
        let voidRelay = PassthroughRelay<Void>()
        var count = 0

        voidRelay
            .sink(receiveValue: { count += 1 })
            .store(in: &subscriptions)

        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()

        XCTAssertEqual(count, 5)
    }

    func testSubscribePublisher() {
        var completed = false
        relay?
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { self.values.append($0) }
            )
            .store(in: &subscriptions)

        ["1", "2", "3"]
            .publisher
            .subscribe(relay!)
            .store(in: &subscriptions)

        XCTAssertFalse(completed)
        XCTAssertEqual(values, ["1", "2", "3"])
    }

    func testSubscribeRelay_Passthroughs() {
        var completed = false

        let input = PassthroughRelay<String>()
        let output = PassthroughRelay<String>()

        input
            .subscribe(output)
            .store(in: &subscriptions)
        output
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { self.values.append($0) }
            )
            .store(in: &subscriptions)

        input.accept("1")
        input.accept("2")
        input.accept("3")

        XCTAssertFalse(completed)
        XCTAssertEqual(values, ["1", "2", "3"])
    }

    func testSubscribeRelay_CurrentValueToPassthrough() {
        var completed = false

        let input = CurrentValueRelay<String>("initial")
        let output = PassthroughRelay<String>()

        input
            .subscribe(output)
            .store(in: &subscriptions)
        output
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { self.values.append($0) }
            )
            .store(in: &subscriptions)

        input.accept("1")
        input.accept("2")
        input.accept("3")

        XCTAssertFalse(completed)
        XCTAssertEqual(values, ["initial", "1", "2", "3"])
    }

    // MARK: - Memory Leak Tests (Issue #167, PR #168)

    // There was a race condition which caused subscriptions in PassthroughRelay
    // to leak. Details of the race condition are in this PR:
    //
    // https://github.com/CombineCommunity/CombineExt/pull/168
    //
    // The issue is similar to CurrentValueRelay (PR #137). The easiest way to
    // reproduce the race condition is to initialize `cancellables` before `relay`.
    // These tests confirm subscriptions are properly released regardless of
    // initialization order.

    final class StoredObject {
        nonisolated(unsafe) static var storedObjectReleased = false

        let value = 10

        init() {
            Self.storedObjectReleased = false
        }

        deinit {
            Self.storedObjectReleased = true
        }
    }

    final class StoredObject2 {
        nonisolated(unsafe) static var storedObjectReleased = false

        let value = 20

        init() {
            Self.storedObjectReleased = false
        }

        deinit {
            Self.storedObjectReleased = true
        }
    }

    func testSubscriptionIsReleasedWhenRelayIsDeallocatedAndDeclaredAfterCancellables() {
        final class ContainerClass {
            nonisolated(unsafe) static var receivedCompletion = false
            nonisolated(unsafe) static var receivedCancel = false

            // Cancellables comes before the relay
            var cancellables = Set<AnyCancellable>()
            let relay = PassthroughRelay<StoredObject>()

            init() {
                relay
                    .handleEvents(receiveCancel: {
                        Self.receivedCancel = true
                    })
                    .sink(
                        receiveCompletion: { _ in
                            Self.receivedCompletion = true
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables)
            }
        }

        var container: ContainerClass? = ContainerClass()

        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertFalse(ContainerClass.receivedCancel)
        container = nil
        XCTAssertNil(container)

        // Cancellables is deallocated before the relay, so cancel is called
        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertTrue(ContainerClass.receivedCancel)
    }

    func testSubscriptionIsReleasedWhenRelayIsDeallocatedAndDeclaredBeforeCancellables() {
        final class ContainerClass {
            nonisolated(unsafe) static var receivedCompletion = false
            nonisolated(unsafe) static var receivedCancel = false

            // Relay comes before cancellables
            let relay = PassthroughRelay<StoredObject>()
            var cancellables = Set<AnyCancellable>()

            init() {
                relay
                    .handleEvents(receiveCancel: {
                        Self.receivedCancel = true
                    })
                    .sink(
                        receiveCompletion: { _ in
                            Self.receivedCompletion = true
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables)
            }
        }

        var container: ContainerClass? = ContainerClass()

        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertFalse(ContainerClass.receivedCancel)
        container = nil
        XCTAssertNil(container)

        // Relay is deallocated first, so completion is sent
        XCTAssertTrue(ContainerClass.receivedCompletion)
        XCTAssertFalse(ContainerClass.receivedCancel)
    }

    func testStoredObjectsAreReleasedWithWithLatestFromAndDeclaredBeforeCancellables() {
        final class ContainerClass {
            nonisolated(unsafe) static var receivedCompletion = false
            nonisolated(unsafe) static var receivedCancel = false

            // Relays come before cancellables
            let relay = PassthroughRelay<StoredObject>()
            let relay2 = PassthroughRelay<StoredObject2>()
            var cancellables: Set<AnyCancellable>? = Set<AnyCancellable>()

            init() {
                relay
                    .withLatestFrom(relay2)
                    .handleEvents(receiveCancel: {
                        Self.receivedCancel = true
                    })
                    .sink(
                        receiveCompletion: { _ in
                            Self.receivedCompletion = true
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables!)

                // Send initial values so withLatestFrom has something to work with.
                relay2.accept(StoredObject2())
            }
        }

        var container: ContainerClass? = ContainerClass()

        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertFalse(StoredObject.storedObjectReleased)
        XCTAssertFalse(StoredObject2.storedObjectReleased)

        container = nil
        XCTAssertTrue(StoredObject2.storedObjectReleased)
        XCTAssertNil(container)

        // withLatestFrom keeps the relay subscription alive until cancellables are released.
        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertTrue(ContainerClass.receivedCancel)
    }

    func testStoredObjectsAreReleasedWithWithLatestFromAndDeclaredAfterCancellables() {
        final class ContainerClass {
            nonisolated(unsafe) static var receivedCompletion = false
            nonisolated(unsafe) static var receivedCancel = false

            // Cancellables comes before the relays - this is the problematic case
            var cancellables: Set<AnyCancellable>? = Set<AnyCancellable>()
            let relay = PassthroughRelay<StoredObject>()
            let relay2 = PassthroughRelay<StoredObject2>()

            init() {
                relay
                    .withLatestFrom(relay2)
                    .handleEvents(receiveCancel: {
                        Self.receivedCancel = true
                    })
                    .sink(
                        receiveCompletion: { _ in
                            Self.receivedCompletion = true
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables!)

                // Send initial values so withLatestFrom has something to work with.
                relay2.accept(StoredObject2())
            }
        }

        var container: ContainerClass? = ContainerClass()

        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertFalse(StoredObject.storedObjectReleased)
        XCTAssertFalse(StoredObject2.storedObjectReleased)

        // Setting container to nil deallocates cancellables first
        // This should not crash and should properly release objects
        container = nil
        XCTAssertTrue(StoredObject2.storedObjectReleased)
        XCTAssertNil(container)

        // Cancellables deallocated first, so cancel is called
        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertTrue(ContainerClass.receivedCancel)
    }
}
#endif
