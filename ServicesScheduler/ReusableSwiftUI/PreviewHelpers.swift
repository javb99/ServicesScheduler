//
//  PreviewHelpers.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/4/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct AllSizes<V: View>: View {
    let devices: [String] = ["iPhone Xs Max", "iPhone 7", "iPhone SE"]
    var content: () -> V
    var body: some View {
        Group {
            ForEach(devices, id: \.self) { (device: String) in
                self.content().previewDevice(PreviewDevice(rawValue: device)).previewDisplayName(device)
            }
        }
    }
}

struct LightAndDark<V: View>: View {
    var content: () -> V
    var body: some View {
        Group {
            content().environment(\.colorScheme, .light)
            content().environment(\.colorScheme, .dark)
        }
    }
}
