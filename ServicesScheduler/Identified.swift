//
//  Identified.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation

/// Pair a piece of data with a unique id.
struct Identified<ID: Hashable, Value>: Identifiable {
    var id: ID
    var value: Value
    
    init(_ value: Value, id: ID) {
        self.id = id
        self.value = value
    }
}
