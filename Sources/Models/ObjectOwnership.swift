//
//  ObjectOwnership.swift
//  CombineExt
//
//  Created by Dmitry Kuznetsov on 08/05/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

import Foundation

/// The ownership of an object
///
/// - seealso: https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html#ID52
public enum ObjectOwnership {
    /// Keep a strong hold of the object, preventing ARC
    /// from disposing it until its released or has no references.
    case strong

    /// Weakly owned. Does not keep a strong hold of the object,
    /// allowing ARC to dispose it even if its referenced.
    case weak

    /// Unowned. Similar to weak, but implicitly unwrapped so may
    /// crash if the object is released beore being accessed.
    case unowned
}
