//
//  Protected.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/18/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation

struct Protected<Value> {
    
    init(_ value: Value) {
        _value = value
    }
    
    private var lock = NSLock()
    
    public var value: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
    }
    private var _value: Value
    
    public mutating func mutate(_ mutation: (inout Value)->()) {
        lock.lock()
        mutation(&_value)
        lock.unlock()
    }
}
