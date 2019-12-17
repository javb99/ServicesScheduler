//
//  OAuthTokenStoreTests.swift
//  ServicesSchedulerBackendTests
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import XCTest
@testable import Scheduler

class OAuthTokenStoreTests: XCTestCase {
    
    let token = OAuthToken(
        raw: "AToken",
        refreshToken: "ARefresh",
        expiresIn: 2 * 60 * 60,
        createdAt: 0)

    func test_authHeader_noToken_provideNoHeader() {
        let sut = makeSUT()
        XCTAssertNil(sut.authenticationHeader)
    }
    
    func test_authHeader_givenToken_providesCorrectHeader() {
        let sut = makeSUT()
        sut.setToken(token)
        
        let header = sut.authenticationHeader
        
        XCTAssertNotNil(header)
        XCTAssertEqual(header?.key, "Authorization")
        XCTAssertEqual(header?.value, "Bearer " + token.raw)
    }
    
    func test_isAuthenticated_noToken_notAuthenticated() {
        let sut = makeSUT()
        XCTAssertFalse(sut.isAuthenticated)
    }
    
    func test_isAuthenticated_hasToken_isAuthenticated() {
        let sut = makeSUT()
        sut.setToken(token)
        XCTAssertTrue(sut.isAuthenticated)
    }

    func test_setToken_storesToken() {
        var storedToken: OAuthToken? = nil
        let sut = makeSUT(tokenSaver: { token in storedToken = token })
        sut.setToken(token)
        XCTAssertNotNil(storedToken)
    }
    
    func test_loadStoredToken_isAuthenticated() {
        let sut = makeSUT(tokenGetter: { return self.token })
        sut.loadToken()
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    func test_loadStoredToken_noStoredToken_isNotAuthenticated() {
        let sut = makeSUT(tokenGetter: { return nil })
        sut.loadToken()
        XCTAssertFalse(sut.isAuthenticated)
    }
    
    func test_isAuthenticated_tokenExpired_notAuthenticated() {
        let sut = makeSUT(evaluatingAt: { Date(timeIntervalSince1970: (2 * 60 * 60))})
        sut.setToken(token)
        
        XCTAssertNil(sut.authenticationHeader)
        XCTAssertFalse(sut.isAuthenticated)
    }
    
    func test_isAuthenticated_tokenNotExpired_isAuthenticated() {
        let sut = makeSUT(evaluatingAt: { Date(timeIntervalSince1970: (2 * 60 * 60) - 1)})
        sut.setToken(token)
        
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    func test_setToken_refreshToken_isAvailable() {
        let sut = makeSUT()
        sut.setToken(token)
        XCTAssertNotNil(sut.refreshToken)
        XCTAssertEqual(sut.refreshToken, token.refreshToken)
    }
    
    func test_setToken_expiredRefreshToken_isNotAvailable() {
        let sut = makeSUT(evaluatingAt: { Date(timeIntervalSince1970: (90 * 24 * 60 * 60))})
        sut.setToken(token)
        XCTAssertNil(sut.refreshToken)
    }
    
    // MARK: Helpers
    
    func makeSUT(tokenSaver: @escaping (OAuthToken)->() = {_ in}, tokenGetter: @escaping ()->(OAuthToken?) = {return nil}, evaluatingAt: @escaping ()->Date = { Date(timeIntervalSince1970: 0) }) -> OAuthTokenStore {
        return OAuthTokenStore(tokenSaver: tokenSaver, tokenGetter: tokenGetter, now: evaluatingAt)
    }
}
