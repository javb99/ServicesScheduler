//
//  StatusCircle.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 6/27/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct StatusCircle: View {
    var status: PresentableStatus
    
    var body: some View {
        Image(systemName: status.iconName)
            .resizable()
            .foregroundColor(status.color)
            .aspectRatio(1.0, contentMode: .fit)
            .background(Circle()
                .inset(by: 2)
                .fill()
                .foregroundColor(Color.primary)
            )
    }
}

#if DEBUG
struct StatusCircle_Previews : PreviewProvider {
    static var previews: some View {
        LightAndDark {
            ForEach(PresentableStatus.allCases, id: \.iconName) { status in
                StatusCircle(status: status)
            }
        }.previewLayout(.fixed(width: 100, height: 100))
    }
}
#endif
