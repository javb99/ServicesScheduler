//
//  TeamSetService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

enum TeamService {
    
    typealias Function = (MTeam.ID, @escaping Completion<MTeam>) -> ()
    
    static func create(using network: PCODownloadService) -> TeamService.Function {
        return { teamID, completion in
            let endpoint = Endpoints.services.teams[id: teamID]
            network.basicFetch(endpoint, completion: completion)
        }
    }
}

typealias TeamSetService = SetMapService<MTeam.ID, MTeam>
