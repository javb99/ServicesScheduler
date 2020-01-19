//
//  Result.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/18/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

extension Result {
    
    var value: Success? {
        switch self {
        case let .success(v):
            return v
        case .failure:
            return nil
        }
    }
    
    var error: Failure? {
        switch self {
        case .success:
            return nil
        case let .failure(e):
            return e
        }
    }
}
