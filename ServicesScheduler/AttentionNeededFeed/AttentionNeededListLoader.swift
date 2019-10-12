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
            print("Teams: " + teams.values.lazy.flatMap({$0}).compactMap { $0.name }.joined(separator: ", "))
        }
    }
    
    @Published var serviceTypes: [MServiceType] = [] {
        didSet {
            print("Service Types: " + serviceTypes.compactMap{ $0.name }.joined(separator: ", "))
        }
    }
    
    @Published var plans: [MPlan] = [] {
        didSet {
            print("Plans: " + plans.compactMap{ $0.shortDates }.joined(separator: ", "))
        }
    }
    
    @Published var planPeople: [MPlanPerson] = [] {
        didSet {
            print("Plan People: " + planPeople.map{ $0.name + "-" + $0.status.rawValue }.joined(separator: ", "))
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
        network.fetch(Endpoints.teams[id: id]) { (result) in
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
        network.fetch(Endpoints.serviceTypes[id: id]) { (result) in
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
        network.fetch(Endpoints.serviceTypes[id: id].plans.filter(.future)) { (result) in
            self.plansFetchDidComplete(serviceType, result.map { $0.2 })
        }
    }
    
    func plansFetchDidComplete(_ serviceTypeID: String, _ result: Result<ResourceCollectionDocument<Models.Plan>, NetworkError>) {
        guard let plansDoc = try? result.get(), let mPlans = plansDoc.data else {
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
        network.fetch(Endpoints.serviceTypes[id: serviceID].plans[id: planID].teamMembers) { (result) in
            self.teamMembersFetchDidComplete(planID, result.map { $0.2 })
        }
    }
    
    func teamMembersFetchDidComplete(_ planID: ResourceIdentifier<Models.Plan>, _ result: Result<ResourceCollectionDocument<Models.PlanPerson>, NetworkError>) {
        guard let peopleDoc = try? result.get(), let mPlanPeople = peopleDoc.data else {
            print("Error fetching team members: \(result)")
            return
        }
        
        DispatchQueue.main.async {
            self.planPeople.append(contentsOf: mPlanPeople)
        }
    }
}
