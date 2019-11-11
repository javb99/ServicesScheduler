//
//  MyTeamsService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 11/11/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import Combine
import PlanningCenterSwift
import JSONAPISpec

protocol MyTeamsService {
    func load(completion: @escaping (Result<[Resource<Models.Team>], Error>)->())
}

final class NetworkMyTeamsService: MyTeamsService {
    
    let network: URLSessionService
    let meService: MeService
    
    init(network: URLSessionService, meService: MeService) {
        self.network = network
        self.meService = meService
    }
    
    func load(completion: @escaping (Result<[Resource<Models.Team>], Error>)->()) {
        meService.load { result in
            switch result {
            case let .success(person):
                self.loadTeams(for: person, completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func loadTeams(for person: Resource<Models.PeoplePerson>, _ completion: @escaping (Result<[Resource<Models.Team>], Error>)->()) {
        let id = ResourceIdentifier<Models.Person>.raw(person.identifer.id)
        let assignmentsEndpoint = Endpoints.services.people[id: id].personTeamPositionAssignments
        network.fetch(assignmentsEndpoint) { result in
            switch result {
            case let .success(_, _, document):
                let assignments = document.data!
                print(assignments.map { assignment in
                    "Assignment: \(assignment.schedulePreference.rawValue)"
                })
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
