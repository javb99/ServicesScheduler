//
//  NotificationNotSentView.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/8/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct NotificationNotSentView: View {
    @State private var isShowingAlert = false
    var body: some View {
        Button(action: { self.isShowingAlert = true }){
            Image(systemName: "envelope.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .accessibility(label: Text("notification not sent"))
        }.alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("Notification Not Sent"),
                message: Text("You have not sent this notification yet. This assignment won't show up for your volunteer until you do."),
                dismissButton: .default(Text("I understand"))
            )
        }
    }
}

#if DEBUG
struct NotificationNotSentView_Previews : PreviewProvider {
    static var previews: some View {
        LightAndDark {
            NotificationNotSentView()
                .fixedSize().padding().padding()
        }.previewLayout(.sizeThatFits)
    }
}
#endif
