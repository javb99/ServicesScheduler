//
//  Created by Joseph Van Boxtel on 12/15/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct ErrorView: View {
    let title: String
    let description: String
    let actionTitle: String
    let action: ()->()
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .center) {
                Text(verbatim: title)
                    .font(.headline)
                    .padding(.bottom)
                Text(verbatim: description)
            }
            .padding()
            .background(
                Color(.secondarySystemBackground).cornerRadius(8)
            )
            .padding()
            
            Spacer()
            
            Button(action: action) {
                Text(verbatim: actionTitle)
                    .padding()
                    .background(
                        Color(.secondarySystemBackground).cornerRadius(8)
                    )
            }.foregroundColor(.servicesGreen).padding()
        }
        
    }
}

#if DEBUG
struct ErrorView_Previews : PreviewProvider {
    static var previews: some View {
        AllSizes {
            LightAndDark {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(ErrorView(title: "Failed to Log In", description: "Could not connect to the Planning Center servers.", actionTitle: "Go Back to Log In", action: {}))
            }
        }
    }
}
#endif
