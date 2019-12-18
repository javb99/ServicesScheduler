//
//  WebLink.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/18/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI
import UIKit

struct WebLink<Label: View>: View {
    
    let url: URL
    let label: Label
    
    @State private var showingFailure: Bool = false
    
    var body: some View {
        Group {
            Button(action: self.pressed) {
                label
            }
            .alert(isPresented: $showingFailure) {
                Alert(title: Text("Website not available"), message: Text("Could not open \(url.absoluteString)"))
            }
        }
    }
    
    func pressed() {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            showingFailure = true
        }
    }
}

extension URL {
    static func constant(_ staticString: StaticString) -> URL {
        return URL(string: staticString.description)!
    }
}

struct WebLink_Previews: PreviewProvider {
    static var previews: some View {
        WebLink(url: URL.constant("https://google.com"), label: Text("Google"))
    }
}
