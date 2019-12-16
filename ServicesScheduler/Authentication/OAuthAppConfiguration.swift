//
//  OAuthAppConfiguration.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/24/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation

public struct OAuthAppConfiguration {
    
    var credentials: Credentials
    var redirectURI: String
    var scopes: [String]
    /// This is the common part of the url between all the auth endpoints. Does not contain the extra /authorize
    var baseURL: URL
    
    /// The credentials that identify the app to the Planning Center API.
    public struct Credentials {
        
        public var identifier: String
        public var secret: String
        
        public init(identifier: String, secret: String) {
            self.identifier = identifier
            self.secret = secret
        }
    }
    
    public var authorizeEndpoint: URL {
        let queryItems = [URLQueryItem(name: "client_id", value: credentials.identifier),
                          URLQueryItem(name: "client_secret", value: credentials.secret),
                          URLQueryItem(name: "redirect_uri", value: redirectURI),
                          URLQueryItem(name: "response_type", value: "code"),
                          URLQueryItem(name: "scope", value: scopes.joined(separator: " "))]
        
        guard var oAuthURLComps = URLComponents(url: baseURL.appendingPathComponent("authorize"), resolvingAgainstBaseURL: false) else {
            fatalError("Failed to create URLComponents using the baseEndpoint adding authorize.")
        }
        oAuthURLComps.queryItems = queryItems
        return oAuthURLComps.url!
    }
}
