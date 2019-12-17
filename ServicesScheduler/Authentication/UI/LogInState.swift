//
//  LogInState.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/15/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation

enum LogInState {
    // MARK: Active States
    case checkingKeychain
    case browserPrompting
    case loadingAccessToken
    // MARK: Idle States
    case notLoggedIn
    case loggedIn
    case failed(Error)
}
