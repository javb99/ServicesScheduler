//
//  NeededPositionCircle.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/4/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct NeededPositionCircle : View {
    var count: Int
    
    var body: some View {
        Text("\(count)")
            .padding(10)
            .background(Circle().fill(Color.yellow))
    }
}

#if DEBUG
struct NeededPositionCircle_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            NeededPositionCircle(count: 0)
            NeededPositionCircle(count: 1)
            NeededPositionCircle(count: 10)
            NeededPositionCircle(count: 100)
        }.previewLayout(.sizeThatFits)
    }
}
#endif
