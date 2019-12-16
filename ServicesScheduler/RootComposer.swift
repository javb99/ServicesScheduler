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
    
    var browserContext: BrowserContext
    
    internal init(browserContext: BrowserContext) {
        self.browserContext = browserContext
    }
    
    lazy var service = URLSessionService(authenticationProvider: .servicesScheduler)
    
    lazy var feedLoader = AttentionNeededListLoader(network: service)
    lazy var feedPresenter = AttentionNeededListPresenter(loader: feedLoader)
    lazy var rootFolderLoader = FolderLoader(network: service)
    
    lazy var meLoader = NetworkMeService(network: service)
    lazy var teamLoader = NetworkTeamService(network: service)
    lazy var myTeamsLoader = NetworkMyTeamsService(network: service, meService: meLoader, teamService: teamLoader)
    lazy var teamPresenter = MyTeamsScreenPresenter(myTeamsService: myTeamsLoader)
    
    lazy var logInStateMachine = LogInStateMachine(browserAuthorizer: BrowserAuthorizer(app: .servicesScheduler, uiContext: browserContext)) { (_, _) in }
    
    var navigationState = NavigationState()
    
    
    func makeRootView() -> some View {
        LogInProtected {
            DerivedBinding(for: \.currentTab, on: self.navigationState) {
                HomeView(selectedTab: $0, makeTeamsView: self.teamsScreen, makeFeedView: self.feedScreen, makeBrowserView: self.browserScreen)
            }
        }.environmentObject(logInStateMachine)
    }
    
    func teamsScreen() -> some View {
        NavigationView {
            MyTeamsScreen(model: teamPresenter, chooseTeams: { self.navigationState.currentTab = .browse })
                .navigationBarTitle("My Teams")
                .navigationBarItems(trailing: selectAllButton())
                .onAppear{ self.teamPresenter.teamScreenDidAppear() }
        }
    }
    
    func selectAllButton() -> some View {
        DerivedBinding(for: \.selectedTeams, on: teamPresenter) { selection in
            SelectAllButton(
                showSelectAll: selection.wrappedValue.isEmpty,
                selectAll: self.teamPresenter.selectAll,
                deselectAll: self.teamPresenter.deselectAll
            )
        }
    }
    
    func feedScreen() -> some View {
        NavigationView {
            AttentionNeededFeedList(dataSource: feedPresenter)
                .onAppear(perform: {
                    print(self.teamPresenter.selectedTeams)
                    self.feedLoader.load(teams: self.teamPresenter.selectedTeams)
                })
                .navigationBarTitle("Feed")
        }.accentColor(.servicesGreen)
    }
    
    func browserScreen() -> some View {
        NavigationView {
            DerivedBinding(for: \.selectedTeams, on: teamPresenter) { selection in
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
