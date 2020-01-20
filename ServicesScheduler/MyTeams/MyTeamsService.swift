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
    func load(completion: @escaping (Result<[TeamWithServiceType], Error>)->())
}

protocol TeamServiceProtocol {
    func load(team teamID: ResourceIdentifier<Models.Team>, completion: @escaping (Result<TeamWithServiceType, Error>)->())
}

final class NetworkTeamService: TeamServiceProtocol {
    let network: URLSessionService
    
    init(network: URLSessionService) {
        self.network = network
    }
    
    func load(team teamID: ResourceIdentifier<Models.Team>, completion: @escaping (Result<TeamWithServiceType, Error>)->()) {
        network.fetch(Endpoints.services.teams[id: teamID].withServiceType) { result in
            switch result {
            case let .success(_, _, document):
                let team = document.data!
                let serviceType = document.included!.first!
                completion(.success(TeamWithServiceType(team: team, serviceType: serviceType)))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

@dynamicMemberLookup
public struct TeamWithServiceType {
    public var team: Resource<Models.Team>
    public var serviceType: Resource<Models.ServiceType>
    
    public subscript<T>(dynamicMember path: WritableKeyPath<Resource<Models.Team>, T>) -> T {
        get {
            return team[keyPath: path]
        }
        set {
            team[keyPath: path] = newValue
        }
    }
}

final class NetworkMyTeamsService: MyTeamsService {
    
    let network: URLSessionService
    let meService: MeService
    let teamService: TeamServiceProtocol
    
    init(network: URLSessionService, meService: MeService, teamService: TeamServiceProtocol) {
        self.network = network
        self.meService = meService
        self.teamService = teamService
    }
    
    func load(completion: @escaping (Result<[TeamWithServiceType], Error>)->()) {
        meService.load { result in
            switch result {
            case let .success(person):
                self.loadTeams(for: person, completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func loadTeams(for person: Resource<Models.PeoplePerson>, _ completion: @escaping (Result<[TeamWithServiceType], Error>)->()) {
        let id = ResourceIdentifier<Models.Person>.raw(person.identifer.id)
        let assignmentsEndpoint = Endpoints.services.people[id: id].personTeamPositionAssignments
        
        var teams = [TeamWithServiceType]()
        var waitingForTeamsCount = 0
        
        network.fetch(assignmentsEndpoint) { result in
            switch result {
            case let .success(_, _, document):
                let assignments = document.data!
                waitingForTeamsCount = assignments.count
                assignments.forEach {
                    self.loadTeam(for: $0, meID: id) { result in
                        waitingForTeamsCount -= 1
                        switch result {
                        case let .success(team):
                            teams.append(team)
                            if waitingForTeamsCount == 0 {
                                completion(.success(teams.uniq(by: \.identifer)))
                            }
                        case let .failure(error):
                            print("Failed to load team: \(error)")
                            //completion(.failure(error))
                        }
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func loadTeam(for assignment: Resource<Models.PersonTeamPositionAssignment>, meID: ResourceIdentifier<Models.Person>, _ completion: @escaping (Result<TeamWithServiceType, Error>)->()) {
        
        let teamPositionEndpoint = Endpoints.services.people[id: meID].personTeamPositionAssignments[id: assignment.identifer].teamPosition
        network.fetch(teamPositionEndpoint) { result in
            switch result {
            case let .success(_, _, document):
                let teamPosition = document.data!
                let teamID = teamPosition.team.data!
                self.teamService.load(team: teamID, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
