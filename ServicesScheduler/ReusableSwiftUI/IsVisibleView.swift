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
