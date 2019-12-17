//
//  OAuthAuthenticateOperation.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation

public class OAuthAuthenticateOperation {
    public typealias AppCredentials = OAuthAppConfiguration.Credentials
    
    let appCredentials: AppCredentials
    let redirectPath: String
    let tokenLoader: (AuthTokenEndpoint, Completion<OAuthToken>)->()
    
    public init(appCredentials: AppCredentials, redirectTo: String, tokenLoader: @escaping (AuthTokenEndpoint, Completion<OAuthToken>)->()) {
        self.appCredentials = appCredentials
        self.redirectPath = redirectTo
        self.tokenLoader = tokenLoader
    }
    
    public var completion: ( (Result<OAuthToken, Error>)->() )?
    
    public func begin(refreshToken: String) {
        let endpoint = AuthTokenEndpoint(
            refreshToken: refreshToken,
            appCredential: appCredentials,
            redirectURI: redirectPath
        )
        
        fetchToken(endpoint)
    }
    
    public func begin(browserAuthorizer: @escaping (Completion<String>)->()) {
        
        browserAuthorizer() { result in
            switch result {
            case let .success(code):
                let endpoint = AuthTokenEndpoint(
                    browserCode: code,
                    appCredential: appCredentials,
                    redirectURI: redirectPath
                )
                
                fetchToken(endpoint)
                
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }
    
    private func fetchToken(_ endpoint: AuthTokenEndpoint) {
        self.tokenLoader(endpoint) { result in
            completion?(result)
        }
    }
}
