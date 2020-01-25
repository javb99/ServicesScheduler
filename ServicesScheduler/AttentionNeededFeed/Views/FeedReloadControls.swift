//
//  FeedReloadControls.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/25/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct FeedReloadControls: View {
    var isLoading: Bool
    var canLoadMorePlans: Bool
    var loadMorePlans: ()->()
    
    var body: some View {
        Group {
            if isLoading {
                Text("Loading...")
            } else if canLoadMorePlans {
                Button(action: loadMorePlans) {
                    Text("Load more")
                }
            }
        }
    }
}
