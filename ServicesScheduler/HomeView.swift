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
}

struct HomeView<TeamsView: View, FeedView: View, BrowserView: View>: View {
    
    @State var selectedTab: HomeViewTab = .feed
    var makeTeamsView: ()->TeamsView
    var makeFeedView: ()->FeedView
    var makeBrowserView: ()->BrowserView
    
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
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(makeTeamsView: {Text("Teams!!")}, makeFeedView: {Text("Feed!!")}, makeBrowserView: {Text("Browser!!")})
    }
}
