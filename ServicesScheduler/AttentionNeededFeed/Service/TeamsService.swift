//
//  TeamsService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

class TeamsService {
    
    let network: PCODownloadService
    
    init(network: PCODownloadService) {
        self.network = network
    }
    
    func fetchTeams(
        _ teamIDs: Set<MTeam.ID>,
        completion: @escaping Completion<Set<MTeam>>
    ) {
        let endpoints = teamIDs.map { teamID in Endpoints.services.teams[id: teamID] }
        network.fetchGroup(endpoints) { result in
            completion(result.map { $0.asSet() })
        }
    }
}
