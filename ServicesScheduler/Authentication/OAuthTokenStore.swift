//
//  OAuthTokenStore.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

public struct OAuthToken: Codable {
    
    enum CodingKeys: String, CodingKey {
        case raw = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case createdAt = "created_at"
    }
    
    public var raw: String
    public var refreshToken: String
    public var expiresIn: Int
    public var createdAt: Int
    
    public var expiresAt: Date {
        Date(timeIntervalSince1970: TimeInterval(expiresIn + createdAt))
    }
    
    public var refreshTokenExpiresAt: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAt) + 90 * 24 * 60 * 60)
    }
}

public class OAuthTokenStore: AuthenticationProvider {
    let tokenSaver: (OAuthToken?)->()
    let tokenGetter: ()->(OAuthToken?)
    let now: ()->Date
    
    private var token: OAuthToken?
    
    public init(tokenSaver: @escaping (OAuthToken?)->(), tokenGetter: @escaping ()->(OAuthToken?), now: @escaping ()->Date) {
        self.tokenSaver = tokenSaver
        self.tokenGetter = tokenGetter
        self.now = now
    }
    
    public func loadToken() {
        setToken(tokenGetter())
    }
    
    public func setToken(_ token: OAuthToken?) {
        self.token = token
        tokenSaver(token)
    }
    
    public func deleteToken() {
        setToken(nil)
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

extension OAuthTokenStore {
    public convenience init() {
        self.init(tokenSaver: { token in
            do {
                guard let token = token else {
                    try KeychainPasswordItem.authToken.deleteItem()
                    return
                }
                try KeychainPasswordItem.authToken.saveToken(token)
            } catch {
                // In production, silent failure is ok. The token will just be refetched next time. The browser already remembers their credentials so it will still be decently fast.
                // Consider deleting the keychain item in this situation.
                assertionFailure(error.localizedDescription)
            }
        }, tokenGetter: {
            try? KeychainPasswordItem.authToken.readToken()
        }, now: Date.init)
    }
}
