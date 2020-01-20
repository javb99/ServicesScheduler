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

class AttentionNeededListPresenter {
    
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
    
    @Published var plans: [PresentableFeedPlan] = []
    
    @Published var teams: [MPlan.ID: [Team]] = [:]
    func teams(plan: Plan) -> [PresentableFeedTeam] {
        let planID = MPlan.ID(stringLiteral: plan.id)
        let teams = self.teams[planID] ?? []
        let feedTeams: [PresentableFeedTeam] = teams.map { basicTeam in
            let rawTeamID = basicTeam.id
            let neededPositions = self.neededPositions(plan: plan, team: basicTeam)
            let teamMembers = self.teamMembers(plan: plan, team: basicTeam)
            return PresentableFeedTeam(id: PresentableFeedTeam.ID(stringLiteral: rawTeamID), name: basicTeam.value, neededPostions: neededPositions, teamMembers: teamMembers)
        }
        return feedTeams.filter { team in team.teamMembers.isNotEmpty || team.neededPostions.isNotEmpty }
    }
    
    @Published var neededPositions: [MPlan.ID: [MTeam.ID: [PresentableNeededPosition]]] = [:]
    func neededPositions(plan: Plan, team: Team) -> [PresentableNeededPosition] {
        let planID = MPlan.ID(stringLiteral: plan.id)
        let teamID = MTeam.ID(stringLiteral: team.id)
        return neededPositions[planID]?[teamID] ?? []
    }
    
    @Published var teamMembers: [MPlan.ID: [MTeam.ID: [PresentableTeamMember]]] = [:]
    func teamMembers(plan: Plan, team: Team) -> [PresentableTeamMember] {
        let planID = MPlan.ID(stringLiteral: plan.id)
        let teamID = MTeam.ID(stringLiteral: team.id)
        let members = teamMembers[planID]?[teamID] ?? []
        return members.filter { $0.status.iconName == PresentableStatus(.unconfirmed).iconName }
    }
    
    func plansPublisher() -> AnyPublisher<[PresentableFeedPlan], Never> {
        
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
            }).map{ $0.1 }.map { plan in
                PresentableFeedPlan(id: PresentableFeedPlan.ID(stringLiteral: plan.id), sortDate: Date(), date: plan.date, serviceTypeName: plan.serviceTypeName, teams: self.teams(plan: plan))
            }
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
    
    func teamMembersPublisher() -> AnyPublisher<[MPlan.ID: [MTeam.ID: [PresentableTeamMember]]], Never> {
        
        loader.$planPeople.map { mPlanPeople in
            mPlanPeople.group(by: \.plan.data!).mapValues { mPlanPeopleForPlan in
                mPlanPeopleForPlan.group(by: \.team.data!).mapValues { teamMPlanPeople in
                    teamMPlanPeople.createPresentableList()
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func neededPositionsPublisher() -> AnyPublisher<[MPlan.ID: [MTeam.ID: [PresentableNeededPosition]]], Never> {
        
        loader.$neededPositions.map { mNeededPosition in
            mNeededPosition.group(by: \.plan.data!).mapValues { mPositionsForPlan in
                mPositionsForPlan.group(by: \.team.data!).mapValues { teamPositions in
                    teamPositions.createPresentableList()
                }
            }
        }.eraseToAnyPublisher()
    }
}

extension AttentionNeededListPresenter: FeedController {
    
    var canLoadMorePlans: Bool { false }
    
    func loadMorePlans() {
        // Can't.
    }
    
    func reset(for teams: Set<MTeam.ID>) {
        loader.load(teams: teams.map { $0.id }.asSet())
    }
}
