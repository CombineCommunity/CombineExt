//
//  XCTestCase+Fixtures.swift
//  CombineExtTests
//
//  Created by Joe Walsh on 8/19/20.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import XCTest
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension XCTestCase {
    enum TestError: Error {
        case generic
    }
    
    var oneThousandInts: [Int] {
        return Array(1...1000)
    }
    
    var squareTransform: (Int) -> Int {
        return { $0 * $0 }
    }
    
    var squareTransformFailingOnMod10: (Int) throws -> Int {
        let squareTransform = self.squareTransform
        return {
            guard $0 % 10 == 0 else {
                return squareTransform($0)
            }
            throw TestError.generic
        }
    }
    
    func asyncPublishers<Input, Output>(with inputs: [Input], maxDelayMilliseconds: Int = 100, transform: @escaping (Input) throws -> Output) -> [AnyPublisher<Output, TestError>] {
        inputs.map { input in
            Future<Output, TestError> { promise in
                DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0 ... maxDelayMilliseconds))) {
                    do {
                        let output = try transform(input)
                        promise(.success(output))
                    } catch {
                        promise(.failure(.generic))
                    }
                }
            }.eraseToAnyPublisher()
        }
    }
    
    func asyncPublisher<Input, Output>(with inputs: [Input], maxDelayMilliseconds: Int = 100, transform: @escaping (Input) throws -> Output) -> AnyPublisher<Output, TestError> {
        asyncPublishers(with: inputs, maxDelayMilliseconds: maxDelayMilliseconds, transform: transform)
            .merge()
    }
}
