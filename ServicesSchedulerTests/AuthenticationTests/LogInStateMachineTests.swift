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
    
    let token = OAuthToken(raw: "", refreshToken: "", expiresIn: 100, createdAt: 0)
    
    func test_browser_browserSuccessful_loaderSuccessful_movesToLoggedIn() {
        let e = expectation(description: "")
        let tokenStore = OAuthTokenStore(tokenSaver: {_ in }, tokenGetter: {nil}, now: Date.init)
        let browser = MockAuthorizer(code: "successful code")
        let mockLoader = { (cred: AuthInputCredential) -> AnyPublisher<OAuthToken, NetworkError> in
            Just<OAuthToken>(self.token).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
        }
        let sut = LogInStateMachine(
            tokenStore: tokenStore,
            browserAuthorizer: browser,
            fetchAuthToken: mockLoader
        )
        var stateHistory = [LogInState]()
        let stateSink = sut.$state.sink { stateHistory.append($0) }
        let expectSink = sut.$state.filter{ $0 == .loggedIn }.sink { _ in
            e.fulfill()
        }
        
        sut.presentBrowserLogIn()
        
        wait(for: [e], timeout: 2)
        
        XCTAssertEqual(stateHistory, [
            .notLoggedIn,
            .browserPrompting,
            .loadingAccessToken(.browserCode("successful code")),
            .loggedIn
        ])
        
        stateSink.cancel()
        expectSink.cancel()
    }
    
    func test_browser_browserSuccessful_loaderFails_movesToFailed() {
        let e = expectation(description: "")
        let tokenStore = OAuthTokenStore(tokenSaver: {_ in }, tokenGetter: {nil}, now: Date.init)
        let browser = MockAuthorizer(code: "successful code")
        let mockLoader = { (cred: AuthInputCredential) -> AnyPublisher<OAuthToken, NetworkError> in
            Fail(outputType: OAuthToken.self, failure: NetworkError.system(URLError(.timedOut)))
                .eraseToAnyPublisher()
        }
        let sut = LogInStateMachine(
            tokenStore: tokenStore,
            browserAuthorizer: browser,
            fetchAuthToken: mockLoader
        )
        var stateHistory = [LogInState]()
        let stateSink = sut.$state.sink { stateHistory.append($0) }
        let expectSink = sut.$state.filter{ $0 == .failed(NetworkError.system(URLError(.timedOut))) }.sink { _ in
            e.fulfill()
        }
        
        sut.presentBrowserLogIn()
        
        wait(for: [e], timeout: 2)
        
        XCTAssertEqual(stateHistory, [
            .notLoggedIn,
            .browserPrompting,
            .loadingAccessToken(.browserCode("successful code")),
            .failed(NetworkError.system(URLError(.timedOut)))
        ])
        
        stateSink.cancel()
        expectSink.cancel()
    }
}

struct MockAuthorizer: Authorizer {
    var code: BrowserCode = ""
    func requestAuthorization() -> AnyPublisher<BrowserCode, Error> {
        Just<BrowserCode>(code).setFailureType(to: Error.self).eraseToAnyPublisher()
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
