//
//  OAuthAuthenticateOperation.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation

public typealias Completion<T> = (Result<T, Error>)->()

public struct OAuthAppConfiguration {
    
    /// The credentials that identify the app to the Planning Center API.
    public struct Credentials {
        
        public var identifier: String
        public var secret: String
        
        public init(identifier: String, secret: String) {
            self.identifier = identifier
            self.secret = secret
        }
    }
}

import PlanningCenterSwift
public struct AuthTokenEndpoint: Endpoint {
    public let method: HTTPMethod = .post
    
    public let path: Path = ["oauth", "token"]
    
    public typealias RequestBody = Int?
    
    public typealias ResponseBody = Int?
    
    public let queryItems: [URLQueryItem]
    
    init(refreshToken: String, appCredential: OAuthAppConfiguration.Credentials, redirectURI: String) {
        queryItems = []
        
    }
    
    init(browserCode: String, appCredential: OAuthAppConfiguration.Credentials, redirectURI: String) {
        queryItems = []
        
    }
}

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
