//
//  LogInStateMachine.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/16/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift
import Combine
import AuthenticationServices

class LogInStateMachine: ObservableObject {
    
    let tokenStore: OAuthTokenStore
    let browserAuthorizer: Authorizer
    let fetchAuthToken: (AuthInputCredential) -> AnyPublisher<OAuthToken, NetworkError>
    
    @Published private(set) var state: LogInState = .notLoggedIn
    
    private var masterCancellable: AnyCancellable?
    private var currentActionCancellable: AnyCancellable?
    
    init(tokenStore: OAuthTokenStore, browserAuthorizer: Authorizer, fetchAuthToken: @escaping (AuthInputCredential) -> AnyPublisher<OAuthToken, NetworkError>) {
        self.tokenStore = tokenStore
        self.browserAuthorizer = browserAuthorizer
        self.fetchAuthToken = fetchAuthToken
        
        masterCancellable = $state.compactMap { s -> AnyPublisher<LogInState, Never>? in
            switch s {
            case .checkingKeychain:
                return Future<LogInState, Never> { promise in
                    tokenStore.loadToken()
                    if tokenStore.isAuthenticated {
                        promise(.success(.loggedIn))
                    } else if let token = tokenStore.refreshToken {
                        promise(.success(.loadingAccessToken(.refreshToken(token))))
                    } else {
                        promise(.success(.notLoggedIn))
                    }
                }.eraseToAnyPublisher()
                
            case .browserPrompting:
                return browserAuthorizer.requestAuthorization()
                    .map { LogInState.loadingAccessToken(.browserCode($0)) }
                    .catch { (error: Error) -> Just<LogInState> in
                        if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                            return Just(.notLoggedIn)
                        }
                        return Just(.failed(error))
                    }.eraseToAnyPublisher()
                
            case let .loadingAccessToken(credential):
                return self.fetchAuthToken(credential)
                    .handleEvents(receiveOutput: { token in
                        // This is kinda smelly.
                        self.tokenStore.setToken(token)
                    })
                    .map { _ in LogInState.loggedIn }
                    .catch { Just(LogInState.failed($0)) }
                    .eraseToAnyPublisher()
            default:
                return nil
            }
        }
        .map { $0.receive(on: RunLoop.main).assign(to: \.state, on: self) }
        .receive(on: RunLoop.main)
        .assign(to: \.currentActionCancellable, on: self)
    }
    
    func attemptToLoadTokenFromDisk() {
        guard case .notLoggedIn = state else {
            preconditionFailure()
        }
        state = .checkingKeychain
    }
    
    func presentBrowserLogIn() {
        guard case .notLoggedIn = state else {
            preconditionFailure()
        }
        state = .browserPrompting
    }
    
    func goBackToLogIn() {
        guard case .failed(_) = state else {
            preconditionFailure()
        }
        state = .notLoggedIn
    }
    
    func logOut() {
        state = .notLoggedIn
        tokenStore.deleteToken()
    }
    
    func cancel() {
        currentActionCancellable?.cancel()
        currentActionCancellable = nil
        state = .notLoggedIn
    }
}
