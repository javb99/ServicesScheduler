//
//  ServiceTypeTeamsLoader.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/4/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift
import JSONAPISpec

class ServiceTypeTeamsLoader: TeamProvider {
    
    let serviceTypeID: ResourceIdentifier<Models.ServiceType>
    let network: URLSessionService
    @Published var teams: [Team] = []
    
    init(serviceTypeID: ResourceIdentifier<Models.ServiceType>, network: URLSessionService) {
        self.serviceTypeID = serviceTypeID
        self.network = network
    }
    
    func setTeams(_ teams: [MTeam]) {
        self.teams = teams
            .compactMap(MTeam.presentableTeam)
            .sorted(by: {$0.sequenceIndex < $1.sequenceIndex})
            .map{ Identified($0.name, id: $0.id) }
    }
    
    func load() {
        let endpoint = Endpoints.services.serviceTypes[id: serviceTypeID].teams
        network.fetch(endpoint) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(_, _, teamsDoc):
                    self.setTeams(teamsDoc.data ?? [])
                case .failure(_):
                    self.teams = []
                }
            }
        }
    }
}

typealias MTeam = Resource<Models.Team>

/// A team that can be used for the team selection list.
struct PresentableTeam {
    var id: String
    var name: String
    var sequenceIndex: Int
}

extension MTeam {
    static func presentableTeam(_ fullTeam: MTeam) -> PresentableTeam? {
        guard let name = fullTeam.name
             else { return nil }
        let index = fullTeam.sequenceIndex ?? 0
        return PresentableTeam(id: fullTeam.identifer.id, name: name, sequenceIndex: index)
    }
}
