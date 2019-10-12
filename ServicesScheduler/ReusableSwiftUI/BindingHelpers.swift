//
//  BindingHelpers.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/4/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

func does<T: Hashable>(_ binding: Binding<Set<T>>, contain element: T) -> Binding<Bool> {
    Binding(get: { binding.wrappedValue.contains(element) },
            set: { newValue in
        if newValue {
            binding.wrappedValue.insert(element)
        } else {
            binding.wrappedValue.remove(element)
        }
    })
}

func does<T: Equatable>(_ binding: Binding<T?>, equal value: T) -> Binding<Bool> {
    Binding(
        get: { binding.wrappedValue == value },
        set: { newValue in
            if newValue {
                binding.wrappedValue = value
            } else {
                binding.wrappedValue = nil
            }
        }
    )
}

extension Binding where Value == Bool {
    func toggle() {
        wrappedValue = !wrappedValue
    }
}
