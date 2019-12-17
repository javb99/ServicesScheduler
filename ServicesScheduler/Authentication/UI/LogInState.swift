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
        switch self {
        case .welcome:
            return .welcome
        case .welcomeRefreshing(_), .welcomeCheckingKeychain, .browserPrompting, .fetchingToken(browserCode: _):
            return .welcomeLoggingIn
        case let .failed(error):
            return .failed(error)
        case .success(_), .prevSuccessRefreshing(_):
            return .loggedIn
        }
    }
    
    var accessToken: OAuthToken? {
        switch self {
        case let .success(token):
            return token
        default:
            return nil
        }
    }
}
