//
//  PresentableLogInState.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/16/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation

enum PresentableLogInState {
    case welcome
    case welcomeLoggingIn
    case loggedIn
    case failed(Error)
}

extension PresentableLogInState {
    var error: Error? {
        if case let .failed(error) = self {
            return error
        } else {
            return nil
        }
    }
}

extension PresentableLogInState: Equatable {
    static func ==(lhs: PresentableLogInState, rhs: PresentableLogInState) -> Bool {
        switch (lhs, rhs) {
        case (.welcome, .welcome):
            return true
        case (.welcomeLoggingIn, .welcomeLoggingIn):
            return true
        case (.loggedIn, .loggedIn):
            return true
        case let (.failed(lError), .failed(rError)):
            return lError.localizedDescription == rError.localizedDescription
        default:
            return false
        }
    }
}

extension PresentableLogInState: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .welcome:
            hasher.combine(0)
        case .welcomeLoggingIn:
            hasher.combine(1)
            case .loggedIn:
            hasher.combine(2)
        case let .failed(error):
            hasher.combine(error.localizedDescription)
        }
    }
}
