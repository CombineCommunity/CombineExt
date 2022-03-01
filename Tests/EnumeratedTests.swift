#if !os(watchOS)
import Combine
import CombineExt
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class EnumeratedTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()

        super.tearDown()
    }

    func testEnumeratedWithDefaultInitialValueReturnsIndexAndElements() {
        let source = PassthroughSubject<String, Never>()
        var output = [(index: Int, element: String)]()
        var completion: Subscribers.Completion<Never>?

        source.enumerated().sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { output.append($0) }
        ).store(in: &cancellables)

        source.send("1")
        source.send("2")
        source.send("3")
        source.send(completion: .finished)

        XCTAssertEqual(output.map(\.index), [0, 1, 2])
        XCTAssertEqual(output.map(\.element), ["1", "2", "3"])
        XCTAssertEqual(completion, .finished)
    }

    func testEnumeratedWithCustomInitialValueReturnsIndexAndElements() {
        let initial = 10
        let source = PassthroughSubject<String, Never>()
        var output = [(index: Int, element: String)]()
        var completion: Subscribers.Completion<Never>?

        source.enumerated(initial: initial).sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { output.append($0) }
        ).store(in: &cancellables)

        source.send("1")
        source.send("2")
        source.send("3")
        source.send(completion: .finished)

        XCTAssertEqual(output.map(\.index), [initial, initial + 1, initial + 2])
        XCTAssertEqual(output.map(\.element), ["1", "2", "3"])
        XCTAssertEqual(completion, .finished)
    }

    func testEnumeratedWhenUpstreamFailsReturnsIndexAndElements() {
        struct MyError: Error, Equatable {
            let id = UUID()
        }

        let error = MyError()
        let source = PassthroughSubject<String, MyError>()
        var output = [(index: Int, element: String)]()
        var completion: Subscribers.Completion<MyError>?

        source.enumerated().sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { output.append($0) }
        ).store(in: &cancellables)

        source.send("1")
        source.send("2")
        source.send("3")
        source.send(completion: .failure(error))

        XCTAssertEqual(output.map(\.index), [0, 1, 2])
        XCTAssertEqual(output.map(\.element), ["1", "2", "3"])
        XCTAssertEqual(completion, .failure(error))
    }

    func testEnumeratedWhenUpstreamHasNoElementsReturnsNoElements() {
        let source = PassthroughSubject<String, Never>()
        var output = [(index: Int, element: String)]()
        var completion: Subscribers.Completion<Never>?

        source.enumerated().sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { output.append($0) }
        ).store(in: &cancellables)

        source.send(completion: .finished)

        XCTAssert(output.isEmpty)
        XCTAssertEqual(completion, .finished)
    }
}
#endif
