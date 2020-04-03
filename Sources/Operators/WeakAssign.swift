//
//  WeakAssign.swift
//  CombineExt
//
//  Created by Jasdev Singh on 2/04/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Combine

public extension Publisher where Failure == Never {
    /// `weak`ly assigns onto an object at a specified key path.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to assign onto on the referenced object.
    ///   - object: The object reference to assign onto.
    ///
    /// - Returns: A subscription cancellation token.
    func weaklyAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>,
                                       on object: Root) -> AnyCancellable {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}
