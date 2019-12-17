//
//  PresentableLogInState.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/16/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import Combine

enum PresentableLogInState {
    case welcome
    case welcomeLoggingIn
    case loggedIn
    case failed(Error)
}

/// Map the LogInState to a presentable version. Some presentation states require knowledge about the previous state to ensure that the welcome screen isn't displayed while refreshing.
class PresentableLogInStateMachine: ObservableObject {
    @Published var state: PresentableLogInState = .welcome
    private var sub: AnyCancellable?
    
    init(logInState: AnyPublisher<LogInState, Never>) {
        sub = logInState
            .scan((LogInState.notLoggedIn, LogInState.notLoggedIn)) { (prevPair, newState) in
                // Some of the presentable states need to know the previous state.
                return (prevPair.1, newState)
            }
            .map { statesPair -> PresentableLogInState in
                let (prev, cur) = statesPair
                switch (prev, cur) {
                case (_, .notLoggedIn):
                    return .welcome
                case (.loggedIn, .loadingAccessToken):
                    // Simple refresh while using the app case.
                    return .loggedIn
                case (_, .loadingAccessToken):
                    return .welcomeLoggingIn
                case (_, .checkingKeychain):
                    return .welcomeLoggingIn
                case (_, .browserPrompting):
                    return .welcomeLoggingIn
                case (_, .loggedIn):
                    return .loggedIn
                case (_, .failed(let error)):
                    return .failed(error)
                }
            }
            .receive(on: RunLoop.main)
            .assign(to: \.state, on: self)
    }
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
