//
//  ShareReplayTests.swift
//  CombineExtTests
//
//  Created by Hugo Saynac on 9/13/20.
//

#if !os(watchOS)
import Combine
import CombineExt
import XCTest
import CombineSchedulers

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class RetryWithBehaviourTests: XCTestCase {
    private var subscription: AnyCancellable?

    fileprivate enum AnError: Error {
        case someError
    }

    /// Start by proving that our test publisher actually works as intended
    func testFailingPublisher() {
        subscription = failingPublisher(numberOfFailures: 0)
            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: 0)
            )

        subscription = failingPublisher(numberOfFailures: 1)
            .sink(
                receiveCompletion: testCompletion(shouldFail: true),
                receiveValue: testValue(shouldReceive: nil)
            )

        subscription = failingPublisher(numberOfFailures: 2)
            .retry(2)
            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: 2)
            )

        subscription = failingPublisher(numberOfFailures: 2)
            .retry(1)
            .sink(
                receiveCompletion: testCompletion(shouldFail: true),
                receiveValue: testValue(shouldReceive: nil)
            )
    }

    func testImmediateRetry() {
        subscription = failingPublisher(numberOfFailures: 1)
            .retry(.immediate(maxCount: 2), scheduler: DispatchQueue.immediate)

            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: 1)
            )

        subscription = failingPublisher(numberOfFailures: 2)
            .retry(.immediate(maxCount: 2), scheduler: DispatchQueue.immediate)

            .sink(
                receiveCompletion: testCompletion(shouldFail: true),
                receiveValue: testValue(shouldReceive: nil)
            )

        subscription = failingPublisher(numberOfFailures: 9)
            .retry(.immediate(maxCount: 10), scheduler: DispatchQueue.immediate)

            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: 9)
            )

    }

    func testDelayedRetryBasic() {
        let testScheduler = DispatchQueue.test
        subscription = failingPublisher(numberOfFailures: 1)
            .retry(.delayed(maxCount: 2, time: 1.0), scheduler: testScheduler)
            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: 1)
            )

        testScheduler.advance(by: .seconds(1))
    }

    func testDelayedRetryWithNotEnoughTime(){
        let testScheduler = DispatchQueue.test
        subscription = failingPublisher(numberOfFailures: 1)
            .retry(.delayed(maxCount: 2, time: 1.0), scheduler: testScheduler)
            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: nil)
            )

        testScheduler.advance(by: .seconds(0.5))
    }

    func testDelayedRetryWithSeveralFailures() {
        let testScheduler = DispatchQueue.test
        subscription = failingPublisher(numberOfFailures: 2)
            .retry(.delayed(maxCount: 3, time: 1.0), scheduler: testScheduler)
            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: 2)
            )

        testScheduler.advance(by: .seconds(2))
    }

    func testDelayedRetryFailAfterRetries() {
        let testScheduler = DispatchQueue.test
        subscription = failingPublisher(numberOfFailures: 3)
            .retry(.delayed(maxCount: 3, time: 1.0), scheduler: testScheduler)
            .sink(
                receiveCompletion: testCompletion(shouldFail: true),
                receiveValue: testValue(shouldReceive: nil)
            )

        testScheduler.advance(by: .seconds(2))
    }

    func testExponentialDelayedRetry() {
        let testScheduler = DispatchQueue.test
        subscription = failingPublisher(numberOfFailures: 3)
            .retry(.exponentialDelayed(maxCount: 4, initial: 1, multiplier: 1), scheduler: testScheduler)
            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: nil)
            )

        // with a 1 multiplier, we should only receive the success result after
        // 1 + 2 + 4 == 7 seconds
        testScheduler.advance(by: .seconds(6.99)) // failing case

        subscription = failingPublisher(numberOfFailures: 3)
            .retry(.exponentialDelayed(maxCount: 4, initial: 1, multiplier: 1), scheduler: testScheduler)
            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: 3)
            )
        testScheduler.advance(by: .seconds(7)) // success case
    }

    func testCustomDelayedRetry() {
        let testScheduler = DispatchQueue.test
        let delayCalculator: (UInt) -> DispatchQueue.SchedulerTimeType.Stride = { repetition in
            if repetition == 1 {
                return .zero
            } else {
                return .seconds(1)
            }
        }

        // with this delay calculator, the first retry should be immediate
        subscription = failingPublisher(numberOfFailures: 1)
            .retry(.customTimerDelayed(maxCount: 3, delayCalculator: delayCalculator), scheduler: testScheduler)
            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: 1)
            )

        testScheduler.advance()

        // the second delay is 1 so we shouldn't receive a value without moving in time
        subscription = failingPublisher(numberOfFailures: 2)
            .retry(.customTimerDelayed(maxCount: 3, delayCalculator: delayCalculator), scheduler: testScheduler)
            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: nil)
            )

        testScheduler.advance()

        subscription = failingPublisher(numberOfFailures: 2)
            .retry(.customTimerDelayed(maxCount: 3, delayCalculator: delayCalculator), scheduler: testScheduler)
            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: 2)
            )

        testScheduler.advance(by: 1)
    }

    func testShouldRetryPredicateInvalid() {
        // should not retry if the predicate is false
        subscription = failingPublisher(numberOfFailures: 1)
            .retry(.immediate(maxCount: 3),
                   scheduler: DispatchQueue.immediate,
                   shouldRetry: { _ in false })
            .sink(
                receiveCompletion: testCompletion(shouldFail: true),
                receiveValue: testValue(shouldReceive: nil)
            )
    }

    func testShouldRetryPredicateValid() {
        // should not retry if the predicate is false
        subscription = failingPublisher(numberOfFailures: 1)
            .retry(.immediate(maxCount: 3),
                   scheduler: DispatchQueue.immediate,
                   shouldRetry: { $0 as? AnError == .someError })
            .sink(
                receiveCompletion: testCompletion(shouldFail: false),
                receiveValue: testValue(shouldReceive: 1)
            )
    }

    /// creates a publisher that fails a number of time then sends the number of retries thaw were intented
    /// - Parameter numberOfFailures: number of time the publisher should fail before succeeding
    /// - Returns: number of retries
    private func failingPublisher(numberOfFailures: Int) -> AnyPublisher<Int, AnError> {
        var numberOfFailures = numberOfFailures
        var numberOfRetries = 0
        return Deferred {
            Future { promise in
                if numberOfFailures == 0 {
                    promise(.success(numberOfRetries))
                    numberOfFailures -= 1

                } else {
                    promise(.failure(.someError))
                    numberOfFailures -= 1
                    numberOfRetries += 1
                }
            }.eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private func testCompletion(shouldFail: Bool,
                            file: StaticString = #filePath,
                            line: UInt = #line) -> (Subscribers.Completion<RetryWithBehaviourTests.AnError>) -> Void {
    return { completion in
        switch completion {
        case .failure:
            if shouldFail { break }
            else { XCTFail("publisher failed unexpectedly", file: file, line: line) }
        case .finished:
            if shouldFail { XCTFail("publisher did not fail as expected", file: file, line: line) }
            else { break }
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private func testValue(shouldReceive: Int?, file: StaticString = #filePath, line: UInt = #line) -> (Int) -> Void {
    return { receivedValue in
        guard let shouldReceive = shouldReceive else {
            XCTFail("publisher received an unexpected value", file: file, line: line)
            return
        }
        XCTAssertEqual(
            shouldReceive,
            receivedValue,
            "publisher didn't receive the expected number of retries",
            file: file,
            line: line
        )

    }
}

#endif
