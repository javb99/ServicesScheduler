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
                       teamMembersPublisher().assign(to: \.teamMembers, on: self),
                       neededPositionsPublisher().assign(to: \.neededPositions, on: self)]
    }
    
    deinit {
        cancelables.forEach { $0.cancel() }
    }
    
    @Published var plans: [Plan] = []
    
    @Published var teams: [MPlan.ID: [Team]] = [:]
    func teams(plan: Plan) -> [Team] {
        let planID = MPlan.ID(stringLiteral: plan.id)
        let teams = self.teams[planID] ?? []
        return teams.filter { self.teamMembers(plan: plan, team: $0).isEmpty == false }
    }
    
    @Published var neededPositions: [MPlan.ID: [MTeam.ID: [NeededPosition]]] = [:]
    func neededPositions(plan: Plan, team: Team) -> [NeededPosition] {
        let planID = MPlan.ID(stringLiteral: plan.id)
        let teamID = MTeam.ID(stringLiteral: team.id)
        return neededPositions[planID]?[teamID] ?? []
    }
    
    @Published var teamMembers: [MPlan.ID: [MTeam.ID: [TeamMember]]] = [:]
    func teamMembers(plan: Plan, team: Team) -> [TeamMember] {
        let planID = MPlan.ID(stringLiteral: plan.id)
        let teamID = MTeam.ID(stringLiteral: team.id)
        let members = teamMembers[planID]?[teamID] ?? []
        return members.filter { $0.status.iconName == PresentableStatus(.unconfirmed).iconName }
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
                    return mTeams
                        .uniq(by: \MTeam.identifer.id)
                        .map { mTeam in
                            Team(mTeam.name ?? "", id: mTeam.identifer.id)
                        }
                }
                let planIDTeamsPair = plans.map { ($0.identifer, value(for: $0)) }
                // Don't really want to deal with duplicates here...
                return Dictionary(planIDTeamsPair)  { _, planID in planID }
            }.eraseToAnyPublisher()
    }
    
    func teamMembersPublisher() -> AnyPublisher<[MPlan.ID: [MTeam.ID: [TeamMember]]], Never> {
        
        loader.$planPeople.map { mPlanPeople in
            mPlanPeople.group(by: \.plan.data!).mapValues { mPlanPeopleForPlan in
                mPlanPeopleForPlan.group(by: \.team.data!).mapValues { teamMPlanPeople in
                    teamMPlanPeople.createPresentableList()
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func neededPositionsPublisher() -> AnyPublisher<[MPlan.ID: [MTeam.ID: [NeededPosition]]], Never> {
        
        loader.$neededPositions.map { mNeededPosition in
            mNeededPosition.group(by: \.plan.data!).mapValues { mPositionsForPlan in
                mPositionsForPlan.group(by: \.team.data!).mapValues { teamPositions in
                    teamPositions.createPresentableList()
                }
            }
        }.eraseToAnyPublisher()
    }
}

extension Collection where Element == MPlanPerson {
    
    /// Transform  a list of PlanPeople to TeamMembers that can be displayed.
    /// This does the sorting, uniquing, and the merging of positions.
    func createPresentableList() -> [TeamMember] {
        self
        .uniq(by: \.identifer)
        .sorted(by: statusThenNameThenPersonId)
        .mergeAdjacent(ifElementsShare: \MPlanPerson.person.data?.id, merge: MPlanPerson.joinPositions(_:_:))
        .compactMap { (person: MPlanPerson) -> TeamMember? in
            guard let positionName = person.positionName else { return nil }
            return TeamMember(id: person.identifer.id,
                              name: person.name,
                              position: positionName,
                              status: PresentableStatus(person.status))
        }
    }
}

extension Collection where Element == MNeededPosition {
    
    /// Transform  a list of PlanPeople to TeamMembers that can be displayed.
    /// This does the sorting, uniquing, and the merging of positions.
    func createPresentableList() -> [NeededPosition] {
        self
        .uniq(by: \.identifer)
        .compactMap { (mPosition: MNeededPosition) -> NeededPosition? in
            return NeededPosition(
                id: mPosition.identifer.id,
                title: mPosition.positionName,
                count: mPosition.quantity
            )
        }
    }
}

extension MPlanPerson {
    static func joinPositions(_ personA: MPlanPerson, _ personB: MPlanPerson) -> MPlanPerson {
        var sum = personA
        sum.positionName = [personA, personB].compactMap{ $0.positionName }.joined(separator: ", ")
        return sum
    }
}

/// A sort comparison function.
private func statusThenNameThenPersonId(_ personA: MPlanPerson, _ personB: MPlanPerson) -> Bool {
    if personA.status.sortValue != personB.status.sortValue {
        return personA.status.sortValue < personB.status.sortValue
    } else if personA.name != personB.name {
        return personA.name < personB.name
    } else {
        // Protects against different users with the same name.
        return personA.identifer.id < personB.identifer.id
    }
}

private extension Models.PlanPerson.Status {
    var sortValue: Int {
        switch self {
        case .confirmed: return 2
        case .unconfirmed: return 1
        case .declined: return 0
        }
    }
}
