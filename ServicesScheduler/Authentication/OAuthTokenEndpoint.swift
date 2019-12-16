//
//  OAuthTokenEndpoint.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift
import JSONAPISpec

public struct AuthTokenEndpoint: Endpoint {
    
    public let method: HTTPMethod = .post
    
    public let path: Path = ["oauth", "token"]
    
    public typealias RequestBody = Empty
    
    public typealias ResponseBody = OAuthToken
    
    public let queryItems: [URLQueryItem]
    
    public let requiresAuthentication = false
    
    public init(refreshToken: String, appCredential: OAuthAppConfiguration.Credentials, redirectURI: String) {
        queryItems = [
            .init(name: "client_id", value: appCredential.identifier),
            .init(name: "client_secret", value: appCredential.secret),
            .init(name: "refresh_token", value: refreshToken),
            .init(name: "grant_type", value: "refresh_token")
        ]
    }
    
    public init(browserCode: String, appCredential: OAuthAppConfiguration.Credentials, redirectURI: String) {
        queryItems = [
            .init(name: "client_id", value: appCredential.identifier),
            .init(name: "client_secret", value: appCredential.secret),
            .init(name: "code", value: browserCode),
            .init(name: "grant_type", value: "authorization_code")
        ]
    }
}

public enum AuthInputCredential {
    case browserCode(String)
    case refreshToken(String)
}

extension AuthTokenEndpoint {
    public init(credential: AuthInputCredential, appCredential: OAuthAppConfiguration.Credentials, redirectURI: String) {
        switch credential {
        case let .browserCode(code):
            self.init(browserCode: code, appCredential: appCredential, redirectURI: redirectURI)
        case let .refreshToken(token):
            self.init(refreshToken: token, appCredential: appCredential, redirectURI: redirectURI)
        }
    }
}
