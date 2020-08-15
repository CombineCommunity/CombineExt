//
//  Nwise.swift
//  CombineExt
//
//  Created by Bas van Kuijck on 14/08/2020.
//  Copyright © 2020 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// Groups the elements of the source publisher into arrays of N consecutive elements.   
    /// The resulting publisher:    
    ///    - does not emit anything until the source publisher emits at least N elements;
    ///    - emits an array for every element after that;
    ///    - forwards any errors or completed events.
    ///
    /// - parameter size: size of the groups, must be greater than 1
    ///
    /// - returns: A type erased publisher that holds an array with the given size.
    func nwise(_ size: Int) -> AnyPublisher<[Output], Failure> {
        assert(size > 1, "n must be greater than 1")

        return scan([]) { acc, item in Array((acc + [item]).suffix(size)) }
            .filter { $0.count == size }
            .eraseToAnyPublisher()
    }

    /// Groups the elements of the source publisher into tuples of the previous and current elements
    /// The resulting publisher:
    ///    - does not emit anything until the source publisher emits at least 2 elements;
    ///    - emits a tuple for every element after that, consisting of the previous and the current item;
    ///    - forwards any error or completed events.
    ///
    /// - returns: A type erased publisher that holds a tuple with 2 elements.
    func pairwise() -> AnyPublisher<(Output, Output), Failure> {
        nwise(2)
            .map { ($0[0], $0[1]) }
            .eraseToAnyPublisher()
    }
}
#endif
