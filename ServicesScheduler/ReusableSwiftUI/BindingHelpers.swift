//
//  BindingHelpers.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/4/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct DerivedBinding<Observable: ObservableObject, Value, Content: View>: View {
    @ObservedObject var observedObject: Observable
    var keyPath: ReferenceWritableKeyPath<Observable, Value>
    var contentGivenBinding: (Binding<Value>)->Content
    
    init(for path: ReferenceWritableKeyPath<Observable, Value>,
         on observable: Observable,
         @ViewBuilder content: @escaping (Binding<Value>)->Content) {
        _observedObject = .init(initialValue: observable)
        keyPath = path
        contentGivenBinding = content
    }
    
    var body: some View {
        contentGivenBinding($observedObject[dynamicMember: keyPath])
    }
}

// MARK: Debug Printing

extension Binding {
    
    func debugingSetter(name: String = String(describing: Self.self)) -> Self {
        Binding(
            get: { self.wrappedValue },
            set: { (value, transaction) in
                print("\(name).setter(value: \(value), transaction: \(transaction))")
                self.wrappedValue = value
            }
        )
    }
    
    func debugingGetter(name: String = String(describing: Self.self)) -> Self {
        Binding(
            get: {
                print("\(name).getter() -> \(self.wrappedValue)")
                return self.wrappedValue
            },
            set: { self.wrappedValue = $0 }
        )
    }
    
    func debuging(name: String = String(describing: Self.self)) -> Self {
        Binding(
            get: {
                print("\(name).getter() -> \(self.wrappedValue)")
                return self.wrappedValue
            },
            set: { (value, transaction) in
                print("\(name).setter(value: \(value), transaction: \(transaction))")
                self.wrappedValue = value
            }
        )
    }
}

struct BindingTestPreviews: PreviewProvider {
    static var previews: some View {
        ProvideState(initialValue: false) { (binding: Binding<Bool>) in
            Toggle(isOn: binding.debuging()) {
                Text("Toggle")
            }.toggleStyle(CheckmarkStyle())
        }
    }
}

// MARK: Bool logic

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
        wrappedValue.toggle()
    }
}

struct BoolTransitionCondition {
    var matches: (_ old: Bool, _ new: Bool)->(Bool)
    
    static let riseHigh = BoolTransitionCondition{ $0 == false && $1 == true }
    static let fallLow = BoolTransitionCondition{ $0 == true && $1 == false }
    static let setHigh = BoolTransitionCondition{ $1 == true }
    static let setLow = BoolTransitionCondition{ $1 == false }
    static let change = BoolTransitionCondition{ $0 != $1 }
}

extension Binding where Value == Bool {
    /// Returns a new `Binding` that wraps the receiver with a `willSet` callback that is only fired if the transition condition matches.
    func withHook(will transition: BoolTransitionCondition, do action: @escaping ()->()) -> Binding<Bool> {
        withWillSetHook { (old, new) in
            if transition.matches(old, new) {
                action()
            }
        }
    }
    
    /// Returns a new `Binding` that wraps the receiver with a `didSet` callback that is only fired if the transition condition matches.
    func withHook(did transition: BoolTransitionCondition, do action: @escaping ()->()) -> Binding<Bool> {
        withDidSetHook { (old, new) in
            if transition.matches(old, new) {
                action()
            }
        }
    }
    
    func withDidSetHook(_ action: @escaping (_ old: Bool, _ new: Bool)->()) -> Binding<Bool> {
        Binding(get: { self.wrappedValue },
                set: { newValue in
                    self.wrappedValue = newValue
                    action(self.wrappedValue, newValue)
        })
    }
    
    func withWillSetHook(_ action: @escaping (_ old: Bool, _ new: Bool)->()) -> Binding<Bool> {
        Binding(get: { self.wrappedValue },
                set: { newValue in
                    action(self.wrappedValue, newValue)
                    self.wrappedValue = newValue
        })
    }
}
