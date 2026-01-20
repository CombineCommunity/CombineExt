//
//  TestHelpers.swift
//  CombineExtTests
//
//  Created by Shai Mishali on 20/01/26.
//  Copyright © 2026 Combine Community. All rights reserved.
//

#if !os(watchOS)
import Foundation

/// A wrapper to explicitly mark values as @unchecked Sendable for testing purposes.
/// This is used in concurrency tests where we intentionally access Combine publishers
/// from multiple threads to verify thread-safety of operators.
///
/// - Warning: This should only be used in tests where concurrent access is intentional
///   and the operator under test is expected to handle thread-safety internally.
public struct UnsafeSendableBox<T>: @unchecked Sendable {
    public let value: T

    public init(value: T) {
        self.value = value
    }
}
#endif
