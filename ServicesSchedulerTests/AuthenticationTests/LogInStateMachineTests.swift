//
//  LogInStateMachineTests.swift
//  ServicesSchedulerTests
//
//  Created by Joseph Van Boxtel on 12/17/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import XCTest
import Combine
import PlanningCenterSwift
@testable import Scheduler


class LogInStateMachineTests: XCTestCase {

    func test_initialState_isNotLoggedIn() {
        let tokenStore = OAuthTokenStore(tokenSaver: {_ in }, tokenGetter: {nil}, now: Date.init)
        let browser = MockAuthorizer()
        let mockLoader = { (cred: AuthInputCredential) -> AnyPublisher<OAuthToken, NetworkError> in
            Empty<OAuthToken, NetworkError>().eraseToAnyPublisher()
        }
        let sut = LogInStateMachine(
            tokenStore: tokenStore,
            browserAuthorizer: browser,
            fetchAuthToken: mockLoader
        )
        XCTAssertEqual(sut.state, .notLoggedIn)
    }
}

struct MockAuthorizer: Authorizer {
    func requestAuthorization() -> AnyPublisher<BrowserCode, Error> {
        Empty<BrowserCode, Error>().eraseToAnyPublisher()
    }
}

extension LogInState: Equatable {
    public static func ==(lhs: LogInState, rhs: LogInState) -> Bool {
        switch (lhs, rhs) {
        case (.notLoggedIn, .notLoggedIn):
            return true
        case (.loggedIn, .loggedIn):
            return true
        case (.checkingKeychain, .checkingKeychain):
            return true
        case (.browserPrompting, .browserPrompting):
            return true
        case let (.loadingAccessToken(lToken), .loadingAccessToken(rToken)):
            switch (lToken, rToken) {
            case let (.browserCode(lCode), .browserCode(rCode)):
                return lCode == rCode
            case let (.refreshToken(lrefToken), .refreshToken(rrefToken)):
                return lrefToken == rrefToken
            default:
                return false
            }
        case let (.failed(lError), .failed(rError)):
            return lError.localizedDescription == rError.localizedDescription
        default:
            return false
        }
    }
}
