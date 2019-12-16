//
//  BrowserAuthorizer.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/24/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import AuthenticationServices
import UIKit

enum AuthError: Error, LocalizedError {
    case failedToParseQuery
    
    var errorDescription: String? {
        return "Failed to parse code from query string."
    }
}

protocol Authorizer {
    func requestAuthorization(completion: @escaping Completion<String>)
}

class BrowserAuthorizer: Authorizer {
    
    let app: OAuthAppConfiguration
    let uiContext: ASWebAuthenticationPresentationContextProviding
    private var session: ASWebAuthenticationSession?
    
    init(app: OAuthAppConfiguration,
         uiContext: ASWebAuthenticationPresentationContextProviding) {
        self.app = app
        self.uiContext = uiContext
    }
    
    func requestAuthorization(completion: @escaping Completion<String>) {
        session = ASWebAuthenticationSession(url: app.authorizeEndpoint, callbackURLScheme: app.redirectURI) { (url, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let code = url?.codeFromQuery else {
                completion(.failure(AuthError.failedToParseQuery))
                return
            }
            completion(.success(code))
        }
        session?.presentationContextProvider = uiContext
        session?.start()
    }
}

fileprivate extension URL {
    /// Parse out the code from the url query string.
    /// Query should be in the form "code=alskdfjlaskjflakjdlf"
    var codeFromQuery: String? {
        guard let urlComps = URLComponents(url: self, resolvingAgainstBaseURL: true), let code = urlComps.queryItems?.first(where: {$0.name == "code"})?.value else {
            return nil
        }
        return code
    }
}
