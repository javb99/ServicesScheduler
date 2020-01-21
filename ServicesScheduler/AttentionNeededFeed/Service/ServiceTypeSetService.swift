//
//  ServiceTypeSetService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

enum ServiceTypeService {
    
    typealias Function = (MServiceType.ID, @escaping Completion<MServiceType>) -> ()
    
    static func create(using network: PCODownloadService) -> Function {
        return { serviceTypeID, completion in
            let endpoint = Endpoints.services.serviceTypes[id: serviceTypeID]
            network.basicFetch(endpoint, completion: completion)
        }
    }
}

typealias ServiceTypeSetService = SetMapService<MServiceType.ID, MServiceType>
