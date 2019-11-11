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
    
    lazy var meLoader = NetworkMeService(network: service)
    lazy var teamLoader = NetworkTeamService(network: service)
    lazy var myTeamsLoader = NetworkMyTeamsService(network: service, meService: meLoader, teamService: teamLoader)
    
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
                .onAppear{
                    self.teamState.isLoadingMyTeams = true
                    self.myTeamsLoader.load(completion: { result in
                        DispatchQueue.main.async {
                            self.teamState.isLoadingMyTeams = false
                            if let teams = try? result.get() {
                                self.teamState.myTeams = teams
                                    .compactMap(MTeam.presentableTeam)
                                    .sorted(by: {$0.sequenceIndex < $1.sequenceIndex})
                                    .map{ Identified($0.name, id: $0.id) }
                            } else {
                                print("Failed \(result)")
                            }
                        }
                    })
                }
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
