//
//  TeamsService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

typealias TeamService = (MTeam.ID, @escaping Completion<MTeam>) -> ()

class TeamsService: SetMapService<MTeam.ID, MTeam> {
    
    init(teamService: @escaping TeamService) {
        super.init(mapping: teamService)
    }
    
    static func teamService(using network: PCODownloadService)
        -> (MTeam.ID, @escaping Completion<MTeam>) -> ()
    {
        return { teamID, completion in
            let endpoint = Endpoints.services.teams[id: teamID]
            network.basicFetch(endpoint, completion: completion)
        }
    }
    
    func fetchTeams(
        _ teamIDs: Set<MTeam.ID>,
        completion: @escaping Completion<Set<MTeam>>
    ) {
        fetchMapped(teamIDs, completion: completion)
    }
}
extension TeamsService {
    convenience init(network: PCODownloadService) {
        self.init(teamService: Self.teamService(using: network))
    }
}
