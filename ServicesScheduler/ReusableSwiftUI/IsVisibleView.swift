//
//  IsVisibleView.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/12/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

/// Allows the content to know if it is visible as a boolean.
/// Useful for testing loading icons that use a boolean state.
struct IsVisibleView<Content: View>: View {
    @State var isVisible = false
    
    var content: (Bool) -> Content
    
    var body: some View {
        content(isVisible)
            .onAppear()    { self.isVisible = true }
            .onDisappear() { self.isVisible = false }
    }
}

struct ProvideState<Content: View, Value>: View {
    @State var state: Value
    
    var content: (Binding<Value>) -> Content
    
    init(initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>)->Content) {
        _state = State(initialValue: initialValue)
        self.content = content
    }
    
    var body: some View {
        content($state)
    }
}
