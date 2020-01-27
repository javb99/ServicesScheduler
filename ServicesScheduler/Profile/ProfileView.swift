//
//  ProfileView.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/17/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct ProfileView: View {
    var userName: String?
    var logOut: ()->()
    
    var body: some View {
        NavigationView {
            VStack {
                
                WebLink(url: URL.constant("http://josephvb.com/servicesScheduler/privacy-policy"), label: Text("privacy policy"))
                    .padding()
                WebLink(url: URL.constant("http://josephvb.com"), label: Text("about the developer"))
                    .padding()
                
                Spacer()
                
                WebLink(url: URL.constant("https://api.planningcenteronline.com/access_tokens"), label: Text("revoke access"))
                    .padding()
                    .accentColor(.red)
            }
            .padding(.bottom)
            .navigationBarTitle(userName ?? "Profile")
            .navigationBarItems(trailing:
                Button(action: logOut) {
                    Text("log out")
                }
            )
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(logOut: {}).accentColor(.servicesGreen)
    }
}
