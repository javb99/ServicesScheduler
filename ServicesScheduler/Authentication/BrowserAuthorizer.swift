//
//  BrowserAuthorizer.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/24/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import AuthenticationServices
import Combine

enum AuthError: Error, LocalizedError {
    case failedToParseQuery
    
    var errorDescription: String? {
        return "Failed to parse code from query string."
    }
}

protocol Authorizer {
    typealias BrowserCode = String
    func requestAuthorization() -> AnyPublisher<BrowserCode, Error>
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
    
    func requestAuthorization() -> AnyPublisher<BrowserCode, Error> {
        Future<BrowserCode, Error> { resolve in
            self.session = ASWebAuthenticationSession(url: self.app.authorizeEndpoint, callbackURLScheme: self.app.redirectURI) { (url, error) in
                if let error = error {
                    resolve(.failure(error))
                    return
                }
                guard let code = url?.codeFromQuery else {
                    resolve(.failure(AuthError.failedToParseQuery))
                    return
                }
                resolve(.success(code))
            }
            self.session?.prefersEphemeralWebBrowserSession = true
            self.session?.presentationContextProvider = self.uiContext
            self.session?.start()
            }
        .handleEvents(receiveCancel: { self.session?.cancel() })
        .eraseToAnyPublisher()
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
// https://api.planningcenteronline.com/oauth/authorize?client_id=e6e07583544a3ac81356f90f8c60d54023d89a16eced19517b0f840b690fc561&client_secret=0f204b6ead6e45c0df4f25878bd403af58aa4f18b792541396518a5ea578ef26&redirect_uri=services-scheduler://auth/complete&response_type=code&scope=services%20people
// https://api.planningcenteronline.com/oauth/authorize?client_id=e6e07583544a3ac81356f90f8c60d54023d89a16eced19517b0f840b690fc561&client_secret=0f204b6ead6e45c0df4f25878bd403af58aa4f18b792541396518a5ea578ef26&redirect_uri=services-scheduler://auth/complete&response_type=code&scope=services%20people
// https://api.planningcenteronline.com//oauth/authorize?client_id=e6e07583544a3ac81356f90f8c60d54023d89a16eced19517b0f840b690fc561&client_secret=0f204b6ead6e45c0df4f25878bd403af58aa4f18b792541396518a5ea578ef26&redirect_uri=services-scheduler://auth/complete&response_type=code&scope=services%20people
// https://api.planningcenteronline.com//oauth/authorize?client_id=e6e07583544a3ac81356f90f8c60d54023d89a16eced19517b0f840b690fc561&client_secret=0f204b6ead6e45c0df4f25878bd403af58aa4f18b792541396518a5ea578ef26&redirect_uri=servicesscheduler://auth/complete&response_type=code&scope=services%20people
