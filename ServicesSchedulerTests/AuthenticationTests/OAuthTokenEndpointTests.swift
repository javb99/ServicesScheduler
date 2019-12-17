//
//  OAuthTokenEndpointTests.swift
//  ServicesSchedulerTests
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import XCTest
import Scheduler

class OAuthTokenEndpointTests: XCTestCase {

    func test_refresh_configuresCorrectly() {
        let sut = AuthTokenEndpoint(
            refreshToken: "abcd",
            appCredential: .init(identifier: "ID1", secret: "****"),
            redirectURI: "redirected")
        
        let grantType = sut.queryParams.first{$0.name=="grant_type"}?.value
        XCTAssertEqual(grantType, "refresh_token")
        XCTAssertTrue(sut.queryParams.contains(where: {$0.name == "refresh_token"}))
        XCTAssertEqual(sut.queryParams.count, 5)
    }
    
    func test_browser_configuresCorrectly() {
        let sut = AuthTokenEndpoint(
            browserCode: "abcd",
            appCredential: .init(identifier: "ID1", secret: "****"),
            redirectURI: "redirected")
        
        let grantType = sut.queryParams.first{$0.name=="grant_type"}?.value
        XCTAssertEqual(grantType, "authorization_code")
        XCTAssertTrue(sut.queryParams.contains(where: {$0.name == "code"}))
        XCTAssertEqual(sut.queryParams.count, 5)
    }
}
