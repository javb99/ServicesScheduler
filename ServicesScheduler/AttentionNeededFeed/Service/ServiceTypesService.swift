//
//  ServiceTypesService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

typealias ServiceTypeService = (MServiceType.ID, @escaping Completion<MServiceType>) -> ()

class ServiceTypesService: SetMapService<MServiceType.ID, MServiceType> {
    
    init(serviceTypeService: @escaping ServiceTypeService) {
        super.init(mapping: serviceTypeService)
    }
    
    static func serviceTypeService(using network: PCODownloadService)
        -> (MServiceType.ID, @escaping Completion<MServiceType>) -> ()
    {
        return { serviceTypeID, completion in
            let endpoint = Endpoints.services.serviceTypes[id: serviceTypeID]
            network.basicFetch(endpoint, completion: completion)
        }
    }
    
    func fetchServiceTypes(
        _ serviceTypeIDs: Set<MServiceType.ID>,
        completion: @escaping Completion<Set<MServiceType>>
    ) {
        fetchMapped(serviceTypeIDs, completion: completion)
    }
}

extension ServiceTypesService {
    convenience init(network: PCODownloadService) {
        self.init(serviceTypeService: Self.serviceTypeService(using: network))
    }
}
