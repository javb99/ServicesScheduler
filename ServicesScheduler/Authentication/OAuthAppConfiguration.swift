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
}

extension OAuthAppConfiguration {
    static var servicesScheduler: OAuthAppConfiguration {
        return .init(credentials: .init(identifier: "e6e07583544a3ac81356f90f8c60d54023d89a16eced19517b0f840b690fc561", secret: "0f204b6ead6e45c0df4f25878bd403af58aa4f18b792541396518a5ea578ef26"), redirectURI: "services-scheduler://auth/complete", scopes: ["services", "people"], baseURL: URL(string: "https://api.planningcenteronline.com/oauth")!)
    }
}
