//
//  KeychainPasswordItem+Token.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/16/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation

extension KeychainPasswordItem {
    
    /// The Keychain item that holds the OAuth token if it has been saved yet.
    static var servicesSchedulerService = "Services Scheduler"
    static var authToken: KeychainPasswordItem = KeychainPasswordItem(service: Self.servicesSchedulerService, account: "OAuth2 Token")
    
    func readToken() throws -> OAuthToken {
        /*
         Build a query to find the item that matches the service, account and
         access group.
         */
        let decoder = PropertyListDecoder()
        let data = try readSecureData()
        let token = try decoder.decode(OAuthToken.self, from: data)
        return token
    }
    
    func saveToken(_ token: OAuthToken) throws {
        let encoder = PropertyListEncoder()
        let data = try encoder.encode(token)
        try saveData(data)
    }
}
