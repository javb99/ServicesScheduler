//
//  AttentionNeededListLoader.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/5/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift
import JSONAPISpec
import Combine

extension Resource {
    typealias ID = ResourceIdentifier<Type>
}

typealias MServiceType = Resource<Models.ServiceType>
typealias MPlan = Resource<Models.Plan>
typealias MPlanPerson = Resource<Models.PlanPerson>

class AttentionNeededListLoader {
    init(network: URLSessionService) {
        self.network = network
    }
    
    let network: URLSessionService
    
    @Published var teams: [MServiceType.ID: [MTeam]] = [:] {
        didSet {
            print("Teams: " + teams.values.flatMap{$0}.commaSeparated(\.name))
        }
    }
    
    @Published var serviceTypes: [MServiceType] = [] {
        didSet {
            print("Service Types: " + serviceTypes.commaSeparated(\.name))
        }
    }
    
    @Published var plans: [MPlan] = [] {
        didSet {
            print("Plans: " + plans.commaSeparated(\.shortDates))
        }
    }
    
    @Published var planPeople: [MPlanPerson] = [] {
        didSet {
            let peopleNames = planPeople.map{ $0.name + "-" + $0.status.rawValue }.commaSeparated(\.self)
            print("\(planPeople.count) Plan People: " + peopleNames)
        }
    }
    
    var currentLoad: AnyCancellable?
    
    func load(teams: Set<Team.ID>) {
        self.teams.removeAll()
        plans.removeAll()
        serviceTypes.removeAll()
        planPeople.removeAll()
        
        currentLoad?.cancel()
        currentLoad = Publishers.Sequence(sequence: teams)
            .setFailureType(to: NetworkError.self)
            .flatMap{ self.teamPublisher(team: $0) }
            .handleEvents(receiveOutput: { mTeam in
                guard let serviceTypeID = mTeam.serviceType.data else { return }
                DispatchQueue.main.async {
                    if self.teams[serviceTypeID] != nil {
                        self.teams[serviceTypeID]!.append(mTeam)
                    } else {
                        self.teams[serviceTypeID] = [mTeam]
                    }
                }
            })
            .compactMap{ mTeam in mTeam.serviceType.data }
            .flatMap { serviceTypeID in
                self.serviceTypesPublisher(serviceType: serviceTypeID.id)
            }
            .handleEvents(receiveOutput: {(serviceType: MServiceType) in
                DispatchQueue.main.async {
                    self.serviceTypes.append(serviceType)
                }
            })
            .flatMap{ serviceType in
                Just(serviceType).setFailureType(to: NetworkError.self)
                    .combineLatest(
                        self.futurePlansPublisher(forServiceType: serviceType.identifer.id)
                            .prefix(4)
                            .handleEvents(receiveOutput: { (plan: MPlan) in
                                DispatchQueue.main.async {
                                    self.plans.append(plan)
                                }
                            })
                    )
            }
            .flatMap { (both: (MServiceType, MPlan)) in
                self.teamMembersPublisher(forServiceType: both.0.identifer.id, planID: both.1.identifer)
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink{ self.planPeople.append(contentsOf: $0) }
    }
    
    func teamPublisher(team: String) -> AnyPublisher<MTeam, NetworkError> {
        let id = ResourceIdentifier<Models.Team>(stringLiteral: team)
        let endpoint = Endpoints.services.teams[id: id]
        return network.future(for: endpoint)
            .map(\.2.data)
            .compactMap(identity)
            .eraseToAnyPublisher()
    }
    
    func serviceTypesPublisher(serviceType: String) -> AnyPublisher<MServiceType, NetworkError> {
        let id = ResourceIdentifier<Models.ServiceType>(stringLiteral: serviceType)
        let endpoint = Endpoints.services.serviceTypes[id: id]
        return network.future(for: endpoint)
            .map(\.2.data)
            .compactMap(identity)
            .eraseToAnyPublisher()
    }
    
    func futurePlansPublisher(forServiceType serviceType: String) -> AnyPublisher<MPlan, NetworkError> {
        let id = ResourceIdentifier<Models.ServiceType>(stringLiteral: serviceType)
        let endpoint = Endpoints.services.serviceTypes[id: id].plans.filter(.future)
        return network.publisher(for: endpoint)
            .eraseToAnyPublisher()
    }
    
    func teamMembersPublisher(forServiceType serviceTypeID: String, planID: ResourceIdentifier<Models.Plan>) -> AnyPublisher<[Resource<Models.PlanPerson>], NetworkError> {
        let serviceID = ResourceIdentifier<Models.ServiceType>(stringLiteral: serviceTypeID)
        let membersEndpoint = Endpoints.services.serviceTypes[id: serviceID].plans[id: planID].teamMembers
        return network.publisher(for: membersEndpoint)
            .collect()
            .eraseToAnyPublisher()
    }
}
