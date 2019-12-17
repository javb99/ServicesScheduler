//
//  AuthTokenService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/16/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

class AuthTokenService {
    
    var network: PCOService
    var appConfig: OAuthAppConfiguration
    
    init(network: PCOService, appConfig: OAuthAppConfiguration) {
        self.network = network
        self.appConfig = appConfig
    }
    
    func fetchToken(with credential: AuthInputCredential, completion: @escaping Completion<OAuthToken>) {
        let endpoint = AuthTokenEndpoint(credential: credential, appCredential: appConfig.credentials, redirectURI: appConfig.redirectURI)
        // TODO: Only make the request once.
        network.fetch(endpoint, completion: { result in
            completion(result.map{$0.2}.mapError{$0 as Error})
        })
    }
}

/// Allows setting the provider after intialization.
class OptionalAuthenticationProvider: AuthenticationProvider {
    
    weak var wrapped: (AuthenticationProvider & AnyObject)?
    
    var authenticationHeader: (key: String, value: String)? {
        wrapped?.authenticationHeader
    }
}
