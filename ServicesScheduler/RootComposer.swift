//
//  RootComposer.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 11/9/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import PlanningCenterSwift
import SwiftUI

class NavigationState: ObservableObject {
    @Published var currentTab: HomeViewTab = .browse
}

class RootComposer {
    
    lazy var service = URLSessionService(authenticationProvider: .servicesScheduler)
    
    lazy var feedLoader = AttentionNeededListLoader(network: service)
    lazy var feedPresenter = AttentionNeededListPresenter(loader: feedLoader)
    lazy var rootFolderLoader = FolderLoader(network: service)
    
    var navigationState = NavigationState()
    var teamState = MyTeamsScreenStaticModel()
    
    func makeRootView() -> some View {
        DerivedBinding(for: \.currentTab, on: self.navigationState) {
            HomeView(selectedTab: $0, makeTeamsView: self.teamsScreen, makeFeedView: self.feedScreen, makeBrowserView: self.browserScreen)
        }
    }
    
    func teamsScreen() -> some View {
        NavigationView {
            MyTeamsScreen(model: teamState, chooseTeams: { self.navigationState.currentTab = .browse })
                .navigationBarTitle("My Teams")
        }
    }
    
    func feedScreen() -> some View {
        NavigationView {
            AttentionNeededFeedList(dataSource: feedPresenter)
                .onAppear(perform: {
                    print(self.teamState.selectedTeams)
                    self.feedLoader.load(teams: self.teamState.selectedTeams)
                })
                .navigationBarTitle("Feed")
        }.accentColor(.servicesGreen)
    }
    
    func browserScreen() -> some View {
        NavigationView {
            DerivedBinding(for: \.selectedTeams, on: teamState) { selection in
                DynamicFolderContentView(
                    folderName: "Browse",
                    destinationFactory: NetworkRecursiveFolderFactory(
                        network: self.service,
                        provider: self.rootFolderLoader,
                        selection: selection
                    ),
                    provider: self.rootFolderLoader
                )
            }
            
        }
    }
}
