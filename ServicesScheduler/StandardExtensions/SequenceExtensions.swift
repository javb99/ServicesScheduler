//
//  SequenceExtensions.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/5/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation

extension Sequence {
    
    public func mergeAdjacent<Key>(ifElementsShare key: KeyPath<Element, Key>, merge: (Element, Element)->Element) -> [Element] where Key: Equatable {
        var result = [Element]()
        var iterator = self.makeIterator()
        var cur = iterator.next()
        while let current = cur, let next = iterator.next() {
            
            if current[keyPath: key] == next[keyPath: key] {
                cur = merge(current, next)
                // Append to result only after all the adjacent elements matching this have been merged.
            } else {
                result.append(current)
                cur = next
            }
            
        }
        if let current = cur {
            result.append(current)
        }
        return result
    }
}

extension Sequence {
    
    func group<Key>(by key: KeyPath<Element, Key>) -> Dictionary<Key, [Element]> {
        Dictionary(grouping: self, by: { $0[keyPath: key] })
    }
}

extension Collection {
    
    /// Does not maintain order.
    func uniq<Key: Hashable>(by key: KeyPath<Element, Key>) -> Array<Element> {
        var dictionary = [Key: Element]()
        for element in self {
            dictionary[element[keyPath: key]] = element
        }
        return Array(dictionary.values)
    }
}

extension Sequence {
    func commaSeparated(_ keyPath: KeyPath<Element, String?>) -> String {
        self.lazy.compactMap { $0[keyPath: keyPath] }.joined(separator: ", ")
    }
}

extension Sequence {
    /// Compact map that probably shouldn't return nil.
    func assertMap<T>(file: StaticString = #file, function: StaticString = #function, _ transform: (Element)->T?) -> [T] {
        self.compactMap {
            if let successful = transform($0) {
                return successful
            } else {
                print("Assert map failed\nfile: \(file)\nfunction: \(function))\n\($0) -> \(T.self)")
                return nil
            }
        }
    }
}

extension Sequence {
    func sortedLexographically(on keyPath: KeyPath<Element, String>) -> [Element] {
        return sorted(by: {$0[keyPath: keyPath] < $1[keyPath: keyPath]})
    }
}

extension Sequence {
    func pluck<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return map{ $0[keyPath: keyPath] }
    }
}

extension Collection {
    var isNotEmpty: Bool { !isEmpty }
}
