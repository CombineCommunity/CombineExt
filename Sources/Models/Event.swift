//
//  Event.swift
//  CombineExt
//
//  Created by Shai Mishali on 13/03/2020.
//  Copyright © 2019 Combine Community. All rights reserved.
//

/// Repressents a Combine Event
public enum Event<Output, Failure: Swift.Error> {
    case value(Output)
    case failure(Failure)
    case finished
}

extension Event: Equatable where Output: Equatable, Failure: Equatable {
    static public func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.finished, .finished):
            return true
        case (.failure(let e1), .failure(let e2)):
            return e1 == e2
        case (.value(let v1), .value(let v2)):
            return v1 == v2
        default:
            return false
        }
    }
}

extension Event: CustomStringConvertible {
    public var description: String {
        switch self {
        case .value(let v):
            return "value(\(v))"
        case .failure(let e):
            return "failure(\(e))"
        case .finished:
            return "finished"
        }
    }
}

/// A protocol representing `Event` convertible types
public protocol EventConvertible {
    associatedtype Output
    associatedtype Failure: Swift.Error
    
    var event: Event<Output, Failure> { get }
}

extension Event: EventConvertible {
    public var event: Event<Output, Failure> { self }
}
