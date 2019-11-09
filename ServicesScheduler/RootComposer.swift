//
//  RootComposer.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 11/9/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import PlanningCenterSwift
import SwiftUI

class RootComposer {
    
    lazy var service = URLSessionService(authenticationProvider: .servicesScheduler)
    
    lazy var feedLoader = AttentionNeededListLoader(network: service)
    lazy var feedPresenter = AttentionNeededListPresenter(loader: feedLoader)
    
    func makeRootView() -> some View {
        HomeView(selectedTab: .browse, makeTeamsView: self.teamsScreen, makeFeedView: self.feedScreen, makeBrowserView: self.browserScreen)
    }
    
    func teamsScreen() -> some View {
        MyTeamsScreen(model: MyTeamsScreenStaticModel(myTeams: [], isLoadingMyTeams: false, otherTeams: [], selectedTeams: [], chooseTeams: {}))
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
