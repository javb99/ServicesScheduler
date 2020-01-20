//
//  PrimaryOrSecondaryService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation

/// Acts as the primary and uses the secondar in the case of failure of the primary.
class PrimaryOrSecondaryService<Input, Output> {
    typealias Service = (Input, Completion<Output>)->()
    
    let fetch: Service
    
    init(primary: @escaping Service, secondary: @escaping Service) {
        fetch = { input, completion in
            primary(input) { result in
                if let output = result.value {
                    completion(.success(output))
                } else {
                    secondary(input, completion)
                }
            }
        }
    }
}
