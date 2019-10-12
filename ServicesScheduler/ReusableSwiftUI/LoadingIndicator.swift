//
//  LoadingIndicator.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/11/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct LoadingIndicator<Content: View>: View {
    var isSpinning = false
    
    var content: () -> Content
    
    var body: some View {
        content()
            .aspectRatio(1, contentMode: .fit)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(Animation.easeInOut(duration: 3)
                .repeatForever(autoreverses: false))
    }
}

struct LoadingIndicator_Previews: PreviewProvider {
    static var isSpinning = false
    static var previews: some View {
        IsVisibleView {
            LoadingIndicator(isSpinning: $0){
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
            }
        }
        .previewLayout(.fixed(width: 100, height: 100))
        .padding()
    }
}
