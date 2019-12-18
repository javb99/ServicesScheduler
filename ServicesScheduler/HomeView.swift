//
//  HomeView.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 11/8/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

enum HomeViewTab: Int {
    case feed
    case myTeams
    case browse
    case profile
}

struct HomeView<TeamsView: View, FeedView: View, BrowserView: View, ProfileView: View>: View {
    
    @Binding var selectedTab: HomeViewTab
    var makeTeamsView: ()->TeamsView
    var makeFeedView: ()->FeedView
    var makeBrowserView: ()->BrowserView
    var makeProfileView: ()->ProfileView
    
    var body: some View {
        VStack {
            TabView(selection: $selectedTab.debugingSetter(name: "TabViewCurrentTab")) {
                feedTab()
                    .tag(HomeViewTab.feed)
                    .tabItem {
                        Image(systemName: "list.dash")
                        Text("Feed")
                    }
                myTeamsTab()
                    .tag(HomeViewTab.myTeams)
                    .tabItem {
                        Image(systemName: "person.2")
                        Text("Teams")
                    }
                browseTab()
                    .tag(HomeViewTab.browse)
                    .tabItem {
                        Image(systemName: "folder.badge.person.crop")
                        Text("Browse")
                    }
                profileTab()
                    .tag(HomeViewTab.profile)
                    .tabItem {
                        Image(systemName: "person")
                        Text("Profile")
                    }
            }
        }
        .accentColor(.servicesGreen)
    }
    
    func feedTab() -> some View {
        makeFeedView().onAppear { print("Feed!") }
    }
    
    func myTeamsTab() -> some View {
        makeTeamsView().onAppear { print("My Teams!") }
    }
    
    func browseTab() -> some View {
        makeBrowserView().onAppear { print("Browser!") }
    }
    
    func profileTab() -> some View {
        makeProfileView().onAppear { print("Profile!") }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(.browse), makeTeamsView: {Text("Teams!!")}, makeFeedView: {Text("Feed!!")}, makeBrowserView: {Text("Browser!!")}, makeProfileView: {Text("Profile!")})
    }
}
