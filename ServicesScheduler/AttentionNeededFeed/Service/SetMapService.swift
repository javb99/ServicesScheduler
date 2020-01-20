//
//  SetMapService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation

class SetMapService<Input: Hashable, Output: Hashable> {
    
    let mapping: (Input, @escaping Completion<Output>)->()
    
    init(mapping: @escaping (Input, @escaping Completion<Output>) -> ()) {
        self.mapping = mapping
    }
    
    func fetchMapped(
        _ inputSet: Set<Input>,
        completion: @escaping Completion<Set<Output>>
    ) {
        var results = Protected(Set<Output>())
        let group = DispatchGroup()
        inputSet.forEach { input in
            group.enter()
            self.mapping(input) { result in
                if let output = result.value {
                    results.mutate { partialResults in
                        partialResults.insert(output)
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: .global()) {
            completion(.success(results.value))
        }
    }
}
