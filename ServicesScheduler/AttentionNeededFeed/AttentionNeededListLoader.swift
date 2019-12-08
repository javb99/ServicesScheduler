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
    
    var planPeopleCancellables: [AnyCancellable] = []
    @Published var planPeople: [MPlanPerson] = [] {
        didSet {
            print("\(planPeople.count) Plan People: " + planPeople.map{ $0.name + "-" + $0.status.rawValue }.joined(separator: ", "))
        }
    }
    
    func load(teams: Set<Team.ID>) {
        self.teams.removeAll()
        plans.removeAll()
        serviceTypes.removeAll()
        planPeople.removeAll()
        teams.forEach(load(team:))
    }
    
    func load(team: Team.ID) {
        let id = ResourceIdentifier<Models.Team>(stringLiteral: team)
        network.fetch(Endpoints.services.teams[id: id]) { (result) in
            self.teamFetchDidComplete(team, result.map { $0.2 })
        }
    }
    
    func teamFetchDidComplete(_ team: Team.ID, _ result: Result<ResourceDocument<Models.Team>, NetworkError>) {
        guard let teamDoc = try? result.get(), let mTeam = teamDoc.data, let serviceTypeID = mTeam.serviceType.data else {
            print("Error fetching team: \(result)")
            return
        }
        load(serviceType: serviceTypeID.id)
        loadPlans(forServiceType: serviceTypeID.id)
        
        DispatchQueue.main.async {
            if let teams = self.teams[serviceTypeID] {
                self.teams[serviceTypeID] = teams + [mTeam]
            } else {
                self.teams[serviceTypeID] = [mTeam]
            }
        }
    }
    
    func load(serviceType: String) {
        let id = ResourceIdentifier<Models.ServiceType>(stringLiteral: serviceType)
        network.fetch(Endpoints.services.serviceTypes[id: id]) { (result) in
            self.serviceTypeFetchDidComplete(serviceType, result.map { $0.2 })
        }
    }
    
    func serviceTypeFetchDidComplete(_ serviceTypeID: String, _ result: Result<ResourceDocument<Models.ServiceType>, NetworkError>) {
        guard let serviceTypeDoc = try? result.get(), let mServiceType = serviceTypeDoc.data else {
            print("Error fetching service type: \(result)")
            return
        }
        
        DispatchQueue.main.async {
            self.serviceTypes.append(mServiceType)
        }
    }
    
    func loadPlans(forServiceType serviceType: String) {
        let id = ResourceIdentifier<Models.ServiceType>(stringLiteral: serviceType)
        network.fetch(Endpoints.services.serviceTypes[id: id].plans.filter(.future)) { (result) in
            self.plansFetchDidComplete(serviceType, result.map { $0.2 })
        }
    }
    
    func plansFetchDidComplete(_ serviceTypeID: String, _ result: Result<ResourceCollectionDocument<Models.Plan>, NetworkError>) {
        guard let plansDoc = try? result.get(), let mPlans = plansDoc.data?.prefix(3) else {
            print("Error fetching plans: \(result)")
            return
        }
        for plan in mPlans {
            loadTeamMembers(forServiceType: serviceTypeID, planID: plan.identifer)
        }
        
        DispatchQueue.main.async {
            self.plans.append(contentsOf: mPlans)
        }
    }
    
    func loadTeamMembers(forServiceType serviceTypeID: String, planID: ResourceIdentifier<Models.Plan>) {
        let serviceID = ResourceIdentifier<Models.ServiceType>(stringLiteral: serviceTypeID)
        let membersEndpoint = Endpoints.services.serviceTypes[id: serviceID].plans[id: planID].teamMembers
        planPeopleCancellables.append(network.publisher(for: membersEndpoint)
            .subscribe(on: DispatchQueue.global())
            .handleEvents(receiveOutput: { print($0.name) })
            .collect()
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { self.planPeople.append(contentsOf: $0) }
        )
    }
}
