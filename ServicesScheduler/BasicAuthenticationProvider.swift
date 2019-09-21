//
//  BasicAuthenticationProvider.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import PlanningCenterSwift

public struct BasicAuthenticationProvider: AuthenticationProvider {
    public var authenticationHeader: (key: String, value: String)?
    
    /// Creates an object that can be used to authenticate requests
    /// - Parameter id: The user id, must not include the colon ':'
    /// - Parameter password: The password
    public init?(id: String, password: String) {
        guard !id.contains(":") else { return nil }
        
        let value = id + ":" + password
        guard let utf8Value = value.data(using: .utf8) else { return nil }
        let encodedValue = utf8Value.base64EncodedString()
        authenticationHeader = (key: "Authorization", value: "Basic " + encodedValue)
    }
}

extension BasicAuthenticationProvider {
    
    static var servicesScheduler: BasicAuthenticationProvider {
        BasicAuthenticationProvider(id: "f9a88b9dc16aa7d8ba43b9c083cfe83304c7ddd6a17bddf6d5091c7f9a5babe9", password: "fca4cedbc4ed47ba0db2dc74ac94a203dc20779dbc861c9a8b7964a5e189568d")!
    }
}
