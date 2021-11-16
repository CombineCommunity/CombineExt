//
//  MaterializeTests.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 14/03/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
import Combine
import CombineExt

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class MaterializeTests: XCTestCase {
    var subscription: AnyCancellable?
    var values = [Event<String, MyError>]()
    var completed = false
    
    override func setUp() {
        values = []
        completed = false
    }
    
    override func tearDown() {
        subscription?.cancel()
    }

    enum MyError: Swift.Error {
        case someError
    }
    
    func testEmpty() {
        subscription = Empty<String, MyError>()
            .materialize()
            .sink(receiveCompletion: { _ in self.completed = true },
                  receiveValue: { self.values.append($0) })
        
        XCTAssertEqual(values, [.finished])
        XCTAssertTrue(completed)
    }
    
    func testFail() {
        subscription = Fail<String, MyError>(error: .someError)
            .materialize()
            .sink(receiveCompletion: { _ in self.completed = true },
                  receiveValue: { self.values.append($0) })
        
        XCTAssertEqual(values, [.failure(.someError)])
        XCTAssertTrue(completed)
    }
    
    func testFinished() {
        let subject = PassthroughSubject<String, MyError>()
        
        subscription = subject
            .materialize()
            .sink(receiveCompletion: { _ in self.completed = true },
                  receiveValue: { self.values.append($0) })
        
        subject.send("Hello")
        subject.send("There")
        subject.send("World!")
        subject.send(completion: .finished)
        
        XCTAssertEqual(values, [
            .value("Hello"),
            .value("There"),
            .value("World!"),
            .finished
        ])

        XCTAssertTrue(completed)
    }
    
    func testValuesFinished() {
        let subject = PassthroughSubject<String, MyError>()
        var strings = [String]()

        subscription = subject
            .materialize()
            .values()
            .sink(receiveCompletion: { _ in self.completed = true },
                  receiveValue: { strings.append($0) })
        
        subject.send("Hello")
        subject.send("There")
        subject.send("World!")
        subject.send(completion: .finished)
        
        XCTAssertEqual(strings, ["Hello", "There", "World!"])
        XCTAssertTrue(completed)
    }
    
    func testFailuresFinished() {
        let subject = PassthroughSubject<String, MyError>()
        var errors = [MyError]()

        subscription = subject
            .materialize()
            .failures()
            .sink(receiveCompletion: { _ in self.completed = true },
                  receiveValue: { errors.append($0) })
        
        subject.send("Hello")
        subject.send("There")
        subject.send("World!")
        subject.send(completion: .finished)
        
        XCTAssertTrue(errors.isEmpty)
        XCTAssertTrue(completed)
    }
    
    func testError() {
        let subject = PassthroughSubject<String, MyError>()
        
        subscription = subject
            .materialize()
            .sink(receiveCompletion: { _ in self.completed = true },
                  receiveValue: { self.values.append($0) })
        
        subject.send("Hello")
        subject.send("There")
        subject.send("World!")
        subject.send(completion: .failure(.someError))
        subject.send("Meh!")
        
        XCTAssertEqual(values, [
            .value("Hello"),
            .value("There"),
            .value("World!"),
            .failure(.someError)
        ])

        XCTAssertTrue(completed)
    }
    
    func testFailureesFinished() {
        let subject = PassthroughSubject<String, MyError>()
        var errors = [MyError]()

        subscription = subject
            .materialize()
            .failures()
            .sink(receiveCompletion: { _ in self.completed = true },
                  receiveValue: { errors.append($0) })
        
        subject.send("Hello")
        subject.send("There")
        subject.send("World!")
        subject.send(completion: .finished)
        
        XCTAssertTrue(errors.isEmpty)
        XCTAssertTrue(completed)
    }
    
    func testFailuresFailure() {
        let subject = PassthroughSubject<String, MyError>()
        var errors = [MyError]()

        subscription = subject
            .materialize()
            .failures()
            .sink(receiveCompletion: { _ in self.completed = true },
                  receiveValue: { errors.append($0) })
        
        subject.send("Hello")
        subject.send("There")
        subject.send("World!")
        subject.send(completion: .failure(.someError))
        
        XCTAssertEqual(errors, [.someError])
        XCTAssertTrue(completed)
    }
    
    /// Test that when a stream is cancelled, the cancel is propagated upstream
    func testCancelled() {
        let subject = PassthroughSubject<String, MyError>()
        var valueCount = 0
        var cancelCount = 0
        
        subscription = subject
            .handleEvents(receiveCancel: {
                cancelCount += 1
            })
            .materialize()
            .failures()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { _ in valueCount += 1 }
            )
        
        subscription?.cancel()
        subject.send("Hello")
        
        XCTAssertEqual(valueCount, 0, "0 values should be emitted after cancel")
        XCTAssertEqual(cancelCount, 1, "Cancel is reported upstream")
    }
}
#endif
