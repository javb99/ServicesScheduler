//
//  SceneDelegate.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 7/27/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import SwiftUI
import PlanningCenterSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    @State var selection: Set<Team.ID> = []

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let baseURL = URL(string: "https://api.planningcenteronline.com/services/v2/")!
        
        let service = URLSessionService(
            requestBuilder: JSONRequestBuilder(
                baseURL: baseURL,
                authenticationProvider: BasicAuthenticationProvider.servicesScheduler,
                encoder: JSONEncoder.pco
            ),
            responseHandler: JSONResponseHandler(
                decoder: JSONDecoder.pco
            ),
            session: .shared
        )
        let loader = AttentionNeededListPresenter(loader: AttentionNeededListLoader(network: service))
        
        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            
            window.rootViewController = UIHostingController(rootView: Home(service: service, loader: loader))
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}

struct Home: View {
    let service: URLSessionService
    let loader: AttentionNeededListPresenter
    @State var selection: Set<Team.ID> = []
    @State var isShowingBrowser = false
     
    var body: some View {
        NavigationView {
            AttentionNeededFeedList(dataSource: loader)
                .onAppear(perform: load)
                .navigationBarItems(trailing: Button(action: $isShowingBrowser.toggle) { Text("Choose") })
                .sheet(isPresented: self.$isShowingBrowser.withHook(will: .setLow, do: self.load), content: folderBrowser)

        }.accentColor(.servicesGreen)
    }
    
    func folderBrowser() -> some View {
        NavigationView {
            NetworkRecursiveFolderFactory(
                network: service,
                provider: FolderLoader(network: service),
                selection: self.$selection
            )
            .destination(forFolder: PresentableFolder("", id: ""))
        }.onDisappear(perform: load)
    }
    
    func load() {
        loader.loader.load(teams: selection)
    }
}
