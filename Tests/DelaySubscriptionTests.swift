#if !os(watchOS)
import Combine
import CombineExt
import CombineSchedulers
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class DelaySubscriptionTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()

        super.tearDown()
    }

    func testDelaySubscriptionDelaysSubscription() {
        var subscribed = false
        let scheduler = DispatchQueue.testScheduler
        let publisher = Just(1)

        publisher
            .delaySubscription(for: 1, scheduler: scheduler)
            .receive(on: scheduler)
            .handleEvents(receiveSubscription: { _ in subscribed = true })
            .sink { _ in }
            .store(in: &cancellables)

        XCTAssertFalse(subscribed)
        scheduler.advance(by: .milliseconds(500))
        XCTAssertFalse(subscribed)
        scheduler.advance(by: .milliseconds(500))
        XCTAssert(subscribed)
    }
}
#endif
