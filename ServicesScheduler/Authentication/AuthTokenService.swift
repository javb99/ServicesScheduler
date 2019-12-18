//
//  AuthTokenService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/16/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift
import Combine

class AuthTokenService {
    
    var network: PCOCombineService
    var appConfig: OAuthAppConfiguration
    
    init(network: PCOCombineService, appConfig: OAuthAppConfiguration) {
        self.network = network
        self.appConfig = appConfig
    }
    
    func fetchToken(with credential: AuthInputCredential) -> AnyPublisher<OAuthToken, NetworkError> {
        let endpoint = AuthTokenEndpoint(credential: credential, appCredential: appConfig.credentials, redirectURI: appConfig.redirectURI)
        // TODO: Only make the request once.
        return network.future(for: endpoint).map { $0.2 }.eraseToAnyPublisher()
    }
}

/// Allows setting the provider after intialization.
class OptionalAuthenticationProvider: AuthenticationProvider {
    
    weak var wrapped: (AuthenticationProvider & AnyObject)?
    
    var authenticationHeader: (key: String, value: String)? {
        wrapped?.authenticationHeader
    }
}
