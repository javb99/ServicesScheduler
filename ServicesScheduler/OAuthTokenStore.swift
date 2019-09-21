//
//  OAuthTokenStore.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

public struct OAuthToken {
    public init(raw: String, refreshToken: String, expiresAt: Date, refreshTokenExpiresAt: Date) {
        self.raw = raw
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.refreshTokenExpiresAt = refreshTokenExpiresAt
    }
    
    public var raw: String
    public var refreshToken: String
    public var expiresAt: Date
    public var refreshTokenExpiresAt: Date
}

public class OAuthTokenStore: AuthenticationProvider {
    let tokenSaver: (OAuthToken)->()
    let tokenGetter: ()->(OAuthToken?)
    let now: ()->Date
    
    private var token: OAuthToken?
    
    public init(tokenSaver: @escaping (OAuthToken)->(), tokenGetter: @escaping ()->(OAuthToken?), now: @escaping ()->Date) {
        self.tokenSaver = tokenSaver
        self.tokenGetter = tokenGetter
        self.now = now
        setToken(tokenGetter())
    }
    
    public func setToken(_ token: OAuthToken?) {
        self.token = token
        guard let token = token else { return }
        tokenSaver(token)
    }
    
    public var isAuthenticated: Bool {
        authenticationHeader != nil && token!.expiresAt > now()
    }
    
    public var authenticationHeader: (key: String, value: String)? {
        guard let token = token, token.expiresAt > now() else { return nil }
        return (key: "Authorization", value: "Bearer " + token.raw)
    }
    
    public var refreshToken: String? {
        guard let token = token, token.refreshTokenExpiresAt > now() else { return nil }
        return token.refreshToken
    }
}
