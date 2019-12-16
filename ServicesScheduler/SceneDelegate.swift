//
//  SceneDelegate.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 7/27/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    var rootComposer: RootComposer?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            
            let window = UIWindow(windowScene: windowScene)
            let context = BrowserContext(getWindow: {[unowned self] in self.window! })
            let composer = RootComposer(browserContext: context)
            self.rootComposer = composer
            
            window.rootViewController = UIHostingController(rootView: composer.makeRootView())
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
