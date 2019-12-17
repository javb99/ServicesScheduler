//
//  KeychainTests.swift
//  ServicesSchedulerTests
//
//  Created by Joseph Van Boxtel on 12/16/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import XCTest
@testable import Scheduler

class KeychainTests: XCTestCase {
    
    let token = OAuthToken(
        raw: "AToken",
        refreshToken: "ARefresh",
        expiresIn: 2 * 60 * 60,
        createdAt: 0)
    
    func test_readToken_whenNoneSaved_throwsError() {
        Self.resetKeychain()
        let sut = KeychainPasswordItem.authToken
        XCTAssertThrowsError(try sut.readToken())
    }
    
    func test_saveToken_savesCorrectly() {
        Self.resetKeychain()
        let sut = KeychainPasswordItem.authToken
        XCTAssertNoThrow(try sut.saveToken(token))
        let items = try! KeychainPasswordItem.passwordItems(forService: KeychainPasswordItem.servicesSchedulerService)
        XCTAssertEqual(items.count, 1)
    }
    
    func test_readToken_afterSaveToken_readsTokenCorrectly() {
        Self.resetKeychain()
        let sut = KeychainPasswordItem.authToken
        XCTAssertNoThrow(try sut.saveToken(token))
        XCTAssertNoThrow(try sut.readToken())
    }
    
    func test_deleteItem_deletesItem() {
        Self.resetKeychain()
        let sut = KeychainPasswordItem.authToken
        XCTAssertNoThrow(try sut.saveToken(token))
        XCTAssertEqual(try! KeychainPasswordItem.passwordItems(forService: KeychainPasswordItem.servicesSchedulerService).count, 1)
        XCTAssertNoThrow(try sut.deleteItem())
        XCTAssertEqual(try! KeychainPasswordItem.passwordItems(forService: KeychainPasswordItem.servicesSchedulerService).count, 0)
    }
    
    // MARK: Helpers
    
    class func resetKeychain() {
        do {
            let items = try KeychainPasswordItem.passwordItems(forService: KeychainPasswordItem.servicesSchedulerService)
            for item in items {
                try item.deleteItem()
                print("Deleted Item: \(item)")
            }
        } catch {}
    }
}

