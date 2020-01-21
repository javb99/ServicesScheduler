//
//  SetMapService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation

/// Input collection -> Output collection asynchronously as a group.
class MapReduceService<Input, Output> where Input: Sequence, Output: Collection {
    
    let mapper: (Input.Element, @escaping Completion<Output.Element>)->()
    let initialValue: Output
    let reducer: (inout Output, Output.Element)->()
    
    init(mapper: @escaping (Input.Element, @escaping Completion<Output.Element>)->(),
         initialValue: Output,
         reducer: @escaping (inout Output, Output.Element)->()) {
        self.mapper = mapper
        self.initialValue = initialValue
        self.reducer = reducer
    }
    
    func fetch(
        _ input: Input,
        completion: @escaping Completion<Output>
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

class SetMapService<InputElement: Hashable, OutputElement: Hashable>: MapReduceService<Set<InputElement>, Set<OutputElement>> {
    
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

class ArrayMapService<InputElement, OutputElement>: MapReduceService<Array<InputElement>, Array<OutputElement>> {
    
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
