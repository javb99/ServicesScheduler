//
//  BrowserContext.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/16/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import UIKit
import AuthenticationServices

class BrowserContext: NSObject, ASWebAuthenticationPresentationContextProviding {

    let getWindow: ()->UIWindow
    
    init(getWindow: @escaping ()->UIWindow) {
        self.getWindow = getWindow
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> UIWindow {
        return getWindow()
    }
}
