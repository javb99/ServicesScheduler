//
//  LogInState.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/15/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation

enum LogInState {
    case welcome
    case welcomeCheckingKeychain
    case welcomeRefreshing(OAuthToken)
    case browserPrompting
    case fetchingToken(browserCode: String)
    case success(OAuthToken)
    case prevSuccessRefreshing(OAuthToken)
    case failed(Error)
}

extension LogInState {
    var presentable: PresentableLogInState {
        return .loggedIn
    }
}
