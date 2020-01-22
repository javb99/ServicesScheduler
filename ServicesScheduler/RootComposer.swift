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
        
        // Use OptionalAuthenticationProvider to avoid a circular dependency graph.
        // URLSessionService needs a auth provider but the OAuth provider doesn't exist until the service is instantiated.
        let authenticationWrapper = OptionalAuthenticationProvider()
        self.service = URLSessionService(
            requestBuilder: JSONRequestBuilder(
                baseURL: URL(string: "https://api.planningcenteronline.com")!,
                authenticationProvider: authenticationWrapper,
                encoder: JSONEncoder.pco
            ),
            responseHandler: JSONResponseHandler(
                decoder: JSONDecoder.pco
            ),
            session: .shared
        )
        self.authTokenService = AuthTokenService(
            network: service,
            appConfig: .servicesScheduler
        )
        let tokenStore = OAuthTokenStore()
        self.logInStateMachine = LogInStateMachine(
            tokenStore: tokenStore,
            browserAuthorizer: BrowserAuthorizer(
                app: .servicesScheduler,
                uiContext: browserContext
            ),
            fetchAuthToken: authTokenService.fetchToken(with:)
        )
        authenticationWrapper.wrapped = tokenStore
        logInStateMachine.attemptToLoadTokenFromDisk()
    }
    
    let service: URLSessionService
    let authTokenService: AuthTokenService
    let logInStateMachine: LogInStateMachine
    
    let coreServices = CoreServicesComposer()
    
    lazy var feedPresenter = FeedComposer.createFeedController(network: service, teamCache: coreServices.teamCache, serviceTypeCache: coreServices.serviceTypeCache) as! ConcreteFeedController//AttentionNeededListPresenter(loader: feedLoader)
    lazy var rootFolderLoader = FolderLoader(network: service)
    
    lazy var teamPresenter = MyTeamsComposer.createPresenter(network: service, teamObserver: coreServices.observeTeamWithServiceTypeService)
    
    var navigationState = NavigationState()
    
    func makeRootView() -> some View {
        LogInProtected {
            DerivedBinding(for: \.currentTab, on: self.navigationState) {
                HomeView(selectedTab: $0, makeTeamsView: self.teamsScreen, makeFeedView: self.feedScreen, makeBrowserView: self.browserScreen, makeProfileView: self.profileScreen)
            }
        }
        .environmentObject(logInStateMachine)
        .environmentObject(PresentableLogInStateMachine(logInState: logInStateMachine.$state.eraseToAnyPublisher()))
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
            FeedListContainer(
                controller: feedPresenter,
                selectedTeams: self.teamPresenter.selectedTeams
            ).navigationBarTitle("Feed")
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
    
    func profileScreen() -> some View {
        ProfileView(logOut: logInStateMachine.logOut)
    }
}
