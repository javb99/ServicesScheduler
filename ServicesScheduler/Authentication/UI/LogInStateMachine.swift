//
//  LogInStateMachine.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/16/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation

class LogInStateMachine: ObservableObject {
    
    let browserAuthorizer: Authorizer
    let fetchAuthToken: (AuthInputCredential, @escaping Completion<OAuthToken>)->()
    
    @Published var state: LogInState = .welcome
    
    init(browserAuthorizer: Authorizer, fetchAuthToken: @escaping (AuthInputCredential, @escaping Completion<OAuthToken>)->()) {
        self.browserAuthorizer = browserAuthorizer
        self.fetchAuthToken = fetchAuthToken
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
        state = .fetchingToken(browserCode: browserCode)
        self.fetchAuthToken(.browserCode(browserCode)) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(token):
                    self.state = .success(token)
                case let .failure(error):
                    self.state = .failed(error)
                }
            }
        }
    }
    
    func refreshToken() {
        guard case let .success(oldToken) = state else {
            preconditionFailure()
        }
        state = .prevSuccessRefreshing(oldToken)
        self.fetchAuthToken(.refreshToken(oldToken.refreshToken)) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(token):
                    self.state = .success(token)
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
