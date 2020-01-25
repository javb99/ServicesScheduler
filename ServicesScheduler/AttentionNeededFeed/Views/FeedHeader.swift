//
//  FeedHeader.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/25/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct FeedHeader: View {
    
    var breakdown: FeedBreakdown
    
    var body: some View {
        VStack {
            Text("Next 30 days")
                .font(.title)
            PlanBreakdownView(breakdown: breakdown)
        }.frame(maxWidth: .greatestFiniteMagnitude)
    }
}
