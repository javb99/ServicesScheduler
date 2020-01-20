//
//  ServiceTypesService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

class ServiceTypesService {
    
    let network: PCODownloadService
    
    init(network: PCODownloadService) {
        self.network = network
    }
    
    func fetchServiceTypes(
        _ serviceTypeIDs: Set<MServiceType.ID>,
        completion: @escaping Completion<Set<MServiceType>>
    ) {
        let endpoints = serviceTypeIDs.map { serviceTypeID in
            Endpoints.services.serviceTypes[id: serviceTypeID]
        }
        network.fetchGroup(endpoints) { result in
            completion(result.map { $0.asSet() })
        }
    }
}
