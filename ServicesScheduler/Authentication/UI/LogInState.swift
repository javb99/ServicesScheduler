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
    case welcomeRefreshing
    case browserPrompting
    case fetchingToken
    case success
    case prevSuccessRefreshing
    case failed(Error)
}

extension LogInState {
    var presentable: PresentableLogInState {
        switch self {
        case .welcome:
            return .welcome
        case .welcomeRefreshing, .welcomeCheckingKeychain, .browserPrompting, .fetchingToken:
            return .welcomeLoggingIn
        case let .failed(error):
            return .failed(error)
        case .success, .prevSuccessRefreshing:
            return .loggedIn
        }
    }
}
