//
//  AttentionNeededListPresenter.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/5/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift
import JSONAPISpec
import Combine

class AttentionNeededListPresenter: AttentionNeededFeedDataSource {
    
    let loader: AttentionNeededListLoader
    var cancelables: [Cancellable] = []
    
    init(loader: AttentionNeededListLoader) {
        self.loader = loader
        cancelables = [plansPublisher().assign(to: \.plans, on: self),
                       teamsPublisher().assign(to: \.teams, on: self),
                       teamMembersPublisher().assign(to: \.teamMembers, on: self)]
    }
    
    deinit {
        cancelables.forEach { $0.cancel() }
    }
    
    @Published var plans: [Plan] = []
    
    @Published var teams: [MPlan.ID: [Team]] = [:]
    func teams(plan: Plan) -> [Team] {
        let planID = MPlan.ID(stringLiteral: plan.id)
        return teams[planID] ?? []
    }
    
    func neededPositions(plan: Plan, team: Team) -> [NeededPosition] {
        return []
    }
    
    @Published var teamMembers: [MPlan.ID: [MTeam.ID: [TeamMember]]] = [:]
    func teamMembers(plan: Plan, team: Team) -> [TeamMember] {
        let planID = MPlan.ID(stringLiteral: plan.id)
        let teamID = MTeam.ID(stringLiteral: team.id)
        return teamMembers[planID]?[teamID] ?? []
    }
    
    func plansPublisher() -> AnyPublisher<[Plan], Never> {
        
        return loader.$plans.map { mplans in
            let serviceTypesById = Dictionary(self.loader.serviceTypes.map{ ($0.identifer, $0) }) { _, serviceType in serviceType }
            
            let datesAndPlans = mplans.compactMap { mplan -> (Date, Plan)? in
                guard let serviceTypeId = mplan.serviceType?.data,
                    let serviceTypeName = serviceTypesById[serviceTypeId]?.name else {
                    
                    print("Plan was filtered due to lack of a service type / name.")
                    return nil
                }
                guard let dates = mplan.shortDates else { return nil }
                
                return (mplan.sortDate ?? Date(), Plan(id: mplan.identifer.id, date: dates, serviceTypeName: serviceTypeName) )
            }
            return datesAndPlans.uniq(by: \.1.id).sorted(by: { (a, b) in
                let (sortA, _) = a
                let (sortB, _) = b
                return sortA < sortB
            }).map{ $0.1 }
        }.eraseToAnyPublisher()
    }
    
    func teamsPublisher() -> AnyPublisher<[MPlan.ID: [Team]], Never> {
        loader.$teams.combineLatest(loader.$plans)
            .map { (teamsByServiceType, plans) in
                func value(for plan: MPlan) -> [Team] {
                    guard let serviceType = plan.serviceType?.data else { return [] }
                    guard let mTeams = teamsByServiceType[serviceType] else { return [] }
                    return mTeams.uniq(by: \MTeam.identifer.id).map { mTeam in
                        Team(mTeam.name ?? "", id: mTeam.identifer.id)
                    }
                }
                let planIDTeamsPair = plans.map { ($0.identifer, value(for: $0)) }
                // Don't really want to deal with duplicates here...
                return Dictionary(planIDTeamsPair)  { _, planID in planID }
            }.eraseToAnyPublisher()
    }
    
    func teamMembersPublisher() -> AnyPublisher<[MPlan.ID: [MTeam.ID: [TeamMember]]], Never> {
        
        return loader.$planPeople.map { mPlanPeople in
            let planPeopleByPlan = Dictionary(grouping: mPlanPeople) { (person: MPlanPerson) in
                return person.plan.data!
            }
            print("plan people by plan: \(planPeopleByPlan.mapValues{ people in people.map { $0.name + "-" + $0.status.rawValue }.joined(separator: ", ") } )")
            return planPeopleByPlan.mapValues { mPlanPeopleForPlan in
                let planPeopleByTeam = Dictionary(grouping: mPlanPeopleForPlan) { (person: MPlanPerson) in
                    return person.team.data!
                }
                return planPeopleByTeam.mapValues { teamMPlanPeople in
                    teamMPlanPeople.compactMap { (person: MPlanPerson) -> TeamMember? in
                        guard let positionName = person.positionName else { return nil }
                        return TeamMember(id: person.identifer.id,
                                          name: person.name + person.identifer.id,
                                          position: positionName,
                                          status: PresentableStatus(person.status))
                    }.uniq(by: \.id)
                }
            }
        }.eraseToAnyPublisher()
    }
}

extension Collection {
    /// Does not maintain order.
    func uniq<Key: Hashable>(by key: KeyPath<Element, Key>) -> Array<Element> {
        var dictionary = [Key: Element]()
        for element in self {
            dictionary[element[keyPath: key]] = element
        }
        return Array(dictionary.values)
    }
}
