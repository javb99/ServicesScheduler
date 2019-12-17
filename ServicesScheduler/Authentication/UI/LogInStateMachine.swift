//
//  LogInStateMachine.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/16/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

class LogInStateMachine: ObservableObject {
    
    let tokenStore: OAuthTokenStore
    let browserAuthorizer: Authorizer
    let fetchAuthToken: (AuthInputCredential, @escaping Completion<OAuthToken>)->()
    
    @Published var state: LogInState = .welcome {
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
        guard case .welcome = state else {
            preconditionFailure()
        }
        state = .welcomeCheckingKeychain
        tokenStore.loadToken()
        if tokenStore.isAuthenticated {
            state = .success
        } else if let token = tokenStore.refreshToken {
            state = .welcomeRefreshing
            refreshToken(token)
        } else {
            state = .welcome
        }
    }
    
    func presentBrowserLogIn() {
        guard case .welcome = state else {
            preconditionFailure()
        }
        state = .browserPrompting
        browserAuthorizer.requestAuthorization() { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(code):
                    self.beginAuthEndpointPost(browserCode: code)
                case let .failure(error):
                    self.state = .failed(error)
                }
            }
            
        }
    }
    
    func beginAuthEndpointPost(browserCode: String) {
        guard case .browserPrompting = state else {
            preconditionFailure()
        }
        state = .fetchingToken
        self.fetchAuthToken(.browserCode(browserCode)) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(token):
                    self.tokenStore.setToken(token)
                    self.state = .success
                case let .failure(error):
                    self.state = .failed(error)
                }
            }
        }
    }
    
    func refreshToken(_ refreshToken: String) {
        self.fetchAuthToken(.refreshToken(refreshToken)) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(token):
                    self.state = .success
                case let .failure(error):
                    self.state = .failed(error)
                }
            }
        }
    }
    
    func goBackToLogIn() {
        guard case .failed(_) = state else {
            preconditionFailure()
        }
        state = .welcome
    }
}
