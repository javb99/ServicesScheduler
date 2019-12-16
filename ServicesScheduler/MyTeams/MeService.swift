//
//  MeService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 11/11/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import Combine
import PlanningCenterSwift
import JSONAPISpec

protocol MeService {
    func load(completion: @escaping (Result<Resource<Models.PeoplePerson>, Error>)->())
}

class NetworkMeService: MeService {
    
    let network: URLSessionService
    
    init(network: URLSessionService) {
        self.network = network
    }
    
    func load(completion: @escaping (Result<Resource<Models.PeoplePerson>, Error>)->()) {
        let meEndpoint = Endpoints.people.me
        network.fetch(meEndpoint) { result in
            #warning("Treat a nil data as a document error and throw an error that contains the errors field.")
            completion(result.map { return $0.2.data! }.mapError{$0 as Error})
        }
    }
}
