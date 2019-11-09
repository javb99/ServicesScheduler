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
    
    var navigationState = NavigationState()
    
    func makeRootView() -> some View {
        DerivedBinding(for: \.currentTab, on: self.navigationState) {
            HomeView(selectedTab: $0, makeTeamsView: self.teamsScreen, makeFeedView: self.feedScreen, makeBrowserView: self.browserScreen)
        }
    }
    
    func teamsScreen() -> some View {
        MyTeamsScreen(model: MyTeamsScreenStaticModel(chooseTeams: { self.navigationState.currentTab = .browse }))
    }
    
    func feedScreen() -> some View {
        NavigationView {
            AttentionNeededFeedList(dataSource: feedPresenter)
                //.onAppear(perform: { self.feedLoader.load(teams: []) })
        }.accentColor(.servicesGreen)
    }
    
    func browserScreen() -> some View {
        NavigationView {
            NetworkRecursiveFolderFactory(
                network: self.service,
                provider: FolderLoader(network: self.service, rootTitle: "Browse"),
                selection: .constant([])
            ).destination(forFolder: PresentableFolder("Browse", id: ""))
        }
    }
}
