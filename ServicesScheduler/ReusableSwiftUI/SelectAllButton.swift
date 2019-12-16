//
//  SelectAllButton.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/8/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct SelectAllButton: View {
    /// false for deselect all.
    var showSelectAll: Bool
    var selectAll: ()->()
    var deselectAll: ()->()
    
    var body: some View {
        Button(action: {
            if self.showSelectAll {
                self.selectAll()
            } else {
                self.deselectAll()
            }
        }) {
            Text(showSelectAll ? "Select all" : "Deselect all")
        }
    }
}
