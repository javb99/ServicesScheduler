//
//  SetMapService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation

/// Converts a sequence to output in parallel while ensuring safe(locked) execution while reducing a given output.
class MapReduceService<Input, Output, Result> where Input: Sequence {
    
    let mapper: (Input.Element, @escaping Completion<Output>)->()
    let initialValue: Result
    let reducer: (inout Result, Output)->()
    
    init(mapper: @escaping (Input.Element, @escaping Completion<Output>)->(),
         initialValue: Result,
         reducer: @escaping (inout Result, Output)->()) {
        self.mapper = mapper
        self.initialValue = initialValue
        self.reducer = reducer
    }
    
    func fetch(
        _ input: Input,
        completion: @escaping Completion<Result>
    ) {
        var results = Protected(initialValue)
        let group = DispatchGroup()
        input.forEach { inputElement in
            group.enter()
            self.mapper(inputElement) { result in
                if let individualOutput = result.value {
                    results.mutate { partialResults in
                        self.reducer(&partialResults, individualOutput)
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

class SetMapService<InputElement: Hashable, OutputElement: Hashable>: MapReduceService<Set<InputElement>, OutputElement, Set<OutputElement>> {
    
    init(mapping: @escaping (InputElement, @escaping Completion<OutputElement>) -> ()) {
        super.init(
            mapper: mapping,
            initialValue: Set(),
            reducer: { partialResults, nextOutput in
                partialResults.insert(nextOutput)
            }
        )
    }
}

class ArrayMapService<InputElement, OutputElement>: MapReduceService<Array<InputElement>, OutputElement, Array<OutputElement>> {
    
    init(mapping: @escaping (InputElement, @escaping Completion<OutputElement>) -> ()) {
        super.init(
            mapper: mapping,
            initialValue: Array(),
            reducer: { partialResults, nextOutput in
                partialResults.append(nextOutput)
            }
        )
    }
}
