//
//  OAuthAuthenticateOperationTests.swift
//  ServicesSchedulerTests
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import XCTest
@testable import Scheduler

class OAuthAuthenticateOperationTests: XCTestCase {

    let creds = OAuthAppConfiguration.Credentials(identifier: "anID", secret: "aSecret")
    
    let token = OAuthToken(
        raw: "AToken",
        refreshToken: "ARefresh",
        expiresIn: 2 * 60 * 60,
        createdAt: 0
    )
    
    func test_refresh_callsAuthTokenLoader() {
        
        var wasTokenLoaderCalled = false
        let tokenLoader: (AuthTokenEndpoint, Completion<OAuthToken>)->() = { endpoint, completion in
            completion(.success(self.token))
            wasTokenLoaderCalled = true
        }
        
        let sut = OAuthAuthenticateOperation(appCredentials: creds, redirectTo: "/yay", tokenLoader: tokenLoader)
        
        sut.begin(refreshToken: "Token")
        XCTAssertTrue(wasTokenLoaderCalled)
    }
    
    func test_refresh_tokenLoaderSuccessful_succeeds() {
        
        var wasTokenLoaderCalled = false
        let tokenLoader: (AuthTokenEndpoint, Completion<OAuthToken>)->() = { endpoint, completion in
            completion(.success(self.token))
            wasTokenLoaderCalled = true
        }
        
        let sut = OAuthAuthenticateOperation(appCredentials: creds, redirectTo: "/yay", tokenLoader: tokenLoader)
        
        var receivedResult: Result<OAuthToken, Error>?
        sut.completion = { result in
            receivedResult = result
        }
        
        sut.begin(refreshToken: "Token")
        
        XCTAssertTrue(wasTokenLoaderCalled)
        XCTAssertNotNil(receivedResult)
        XCTAssertNotNil(try? receivedResult!.get())
    }
    
    func test_browser_browserIsLaunched() {
        var browserWasLaunched = false
        let browserAuth: (Completion<String>)->() = { completion in
            completion(.success("A special code"))
            browserWasLaunched = true
        }
        
        let sut = OAuthAuthenticateOperation(appCredentials: creds, redirectTo: "/yay", tokenLoader: {_,_ in})
        
        sut.begin(browserAuthorizer: browserAuth)
        
        XCTAssertTrue(browserWasLaunched)
    }
    
    func test_browser_browserSuccess_callsAuthTokenLoader() {
        var browserWasLaunched = false
        let browserAuth: (Completion<String>)->() = { completion in
            completion(.success("A special code"))
            browserWasLaunched = true
        }
        
        var wasTokenLoaderCalled = false
        let tokenLoader: (AuthTokenEndpoint, Completion<OAuthToken>)->() = { endpoint, completion in
            completion(.success(self.token))
            wasTokenLoaderCalled = true
        }
        
        let sut = OAuthAuthenticateOperation(appCredentials: creds, redirectTo: "/yay", tokenLoader: tokenLoader)
        
        sut.begin(browserAuthorizer: browserAuth)
        
        XCTAssertTrue(wasTokenLoaderCalled)
        XCTAssertTrue(browserWasLaunched)
    }
    
    func test_browser_browserFailure_doesNotCallTokenLoader() {
        var wasTokenLoaderCalled = false
        let tokenLoader: (AuthTokenEndpoint, Completion<OAuthToken>)->() = { endpoint, completion in
            completion(.success(self.token))
            wasTokenLoaderCalled = true
        }
        
        let sut = OAuthAuthenticateOperation(appCredentials: creds, redirectTo: "/yay", tokenLoader: tokenLoader)
        
        let browserAuth: (Completion<String>)->() = { completion in
            completion(.failure(URLError(.cancelled)))
        }
        
        sut.begin(browserAuthorizer: browserAuth)
        
        XCTAssertFalse(wasTokenLoaderCalled)
    }
    
    func test_browser_browserSuccess_tokenLoads_success() {
        let tokenLoader: (AuthTokenEndpoint, Completion<OAuthToken>)->() = { endpoint, completion in
            completion(.success(self.token))
        }
        
        let sut = OAuthAuthenticateOperation(appCredentials: creds, redirectTo: "/yay", tokenLoader: tokenLoader)
        
        let browserAuth: (Completion<String>)->() = { completion in
            completion(.success("A special code"))
        }
        
        var receivedResult: Result<OAuthToken, Error>?
        sut.completion = { result in
            receivedResult = result
        }
        
        sut.begin(browserAuthorizer: browserAuth)
        
        XCTAssertNotNil(receivedResult)
        XCTAssertNotNil(try? receivedResult?.get())
    }
}
