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
        
        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            
            window.rootViewController = UIHostingController(rootView: Home(service: service))
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}

struct Home: View {
    let service: URLSessionService
    @State var selection: Set<Team.ID> = []
     
    var body: some View {
        NavigationView {
            NetworkRecursiveFolderFactory(
                network: service,
                provider: FolderLoader(network: service),
                selection: self.$selection
            )
            .destination(forFolder: PresentableFolder("", id: ""))
                .accentColor(.servicesGreen)
        }
    }
}

