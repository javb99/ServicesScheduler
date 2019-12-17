//
//  LogInStateMachine.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/16/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift
import AuthenticationServices

class LogInStateMachine: ObservableObject {
    
    let tokenStore: OAuthTokenStore
    let browserAuthorizer: Authorizer
    let fetchAuthToken: (AuthInputCredential, @escaping Completion<OAuthToken>)->()
    
    @Published private(set) var state: LogInState = .notLoggedIn {
        didSet {
            print("Transitioned LogInState from \(oldValue) to \(state)")
        }
    }
    
    init(tokenStore: OAuthTokenStore, browserAuthorizer: Authorizer, fetchAuthToken: @escaping (AuthInputCredential, @escaping Completion<OAuthToken>)->()) {
        self.tokenStore = tokenStore
        self.browserAuthorizer = browserAuthorizer
        self.fetchAuthToken = fetchAuthToken
    }
    
    func attemptToLoadTokenFromDisk() {
        guard case .notLoggedIn = state else {
            preconditionFailure()
        }
        state = .checkingKeychain
        tokenStore.loadToken()
        if tokenStore.isAuthenticated {
            state = .loggedIn
        } else if let token = tokenStore.refreshToken {
            state = .loadingAccessToken
            self.fetchAuthToken(.refreshToken(token), self.handleFetchResult)
        } else {
            state = .notLoggedIn
        }
    }
    
    func presentBrowserLogIn() {
        guard case .notLoggedIn = state else {
            preconditionFailure()
        }
        state = .browserPrompting
        browserAuthorizer.requestAuthorization() { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(code):
                    self.state = .loadingAccessToken
                    self.fetchAuthToken(.browserCode(code), self.handleFetchResult)
                case let .failure(error as ASWebAuthenticationSessionError) where error.code == .canceledLogin:
                    self.state = .notLoggedIn
                case let .failure(error):
                    self.state = .failed(error)
                }
            }
        }
    }
    
    private func handleFetchResult(_ result: Result<OAuthToken, Error>) {
        DispatchQueue.main.async {
            switch result {
            case let .success(token):
                self.tokenStore.setToken(token)
                self.state = .loggedIn
            case let .failure(error):
                self.state = .failed(error)
            }
        }
    }
    
    func goBackToLogIn() {
        guard case .failed(_) = state else {
            preconditionFailure()
        }
        state = .notLoggedIn
    }
}
