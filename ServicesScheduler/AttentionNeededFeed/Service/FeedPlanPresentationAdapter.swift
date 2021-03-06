//
//  FeedPlanPresentationAdapter.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/19/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

class FeedPlanPresentationAdapter {
    
    static func makePresentable(_ feedPlans: [FeedPlan], using allFetchedTeams: Set<MTeam>) -> [PresentableFeedPlan] {
        return feedPlans.map { plan in
            makePresentablePlan(plan, using: allFetchedTeams)
        }.sorted(by: sortDateThenServiceTypeName)
    }
    
    static private func makePresentablePlan(_ feedPlan: FeedPlan, using allFetchedTeams: Set<MTeam>) -> PresentableFeedPlan {
        let teams = allFetchedTeams.filter {
            $0.serviceType.data == feedPlan.serviceTypeID
        }
        let neededPositionsByTeam = feedPlan.neededPositions
            .group(by: \.team.data)
            .mapValues { $0.createPresentableList() }
        let teamMembersByTeam = feedPlan.teamMembers
            .group(by: \.team.data)
            .mapValues { $0.createPresentableList() }
        let presentableTeams = teams
            .sorted { $0.sequenceIndex ?? $0.identifer.hashValue < $1.sequenceIndex ?? $1.identifer.hashValue }
            .compactMap { team -> PresentableFeedTeam? in
            guard let name = team.name else { return nil }
            let neededPositions = neededPositionsByTeam[team.identifer] ?? []
            let teamMembers = teamMembersByTeam[team.identifer] ?? []
            
            let shouldFilterOut = neededPositions.isEmpty && teamMembers.isEmpty
            if shouldFilterOut { return nil }
            
            return PresentableFeedTeam(
                id: team.identifer,
                name: name,
                neededPostions: neededPositions,
                teamMembers: teamMembers
            )
        }
        let plan = PresentableFeedPlan(id: feedPlan.id, sortDate: feedPlan.sortDate, date: feedPlan.date, serviceTypeName: feedPlan.serviceTypeName, teams: presentableTeams)
        return plan
    }
}

extension Collection where Element == MPlanPerson {
    
    /// Transform  a list of PlanPeople to TeamMembers that can be displayed.
    /// This does the sorting, uniquing, and the merging of positions.
    func createPresentableList() -> [PresentableTeamMember] {
        self
        .uniq(by: \.identifer)
        .sorted(by: statusThenNameThenPersonId)
        .mergeAdjacent(ifElementsShare: \MPlanPerson.person.data?.id, merge: MPlanPerson.joinPositions(_:_:))
        .compactMap { (person: MPlanPerson) -> PresentableTeamMember? in
            guard let positionName = person.positionName else { return nil }
            return PresentableTeamMember(id: person.identifer.id,
                              name: person.name,
                              position: positionName,
                              status: PresentableStatus(person.status),
                              hasUnsentNotification: person.isNotificationPrepared)
        }
    }
}

extension Collection where Element == MNeededPosition {
    
    /// Transform  a list of PlanPeople to TeamMembers that can be displayed.
    /// This does the sorting, uniquing, and the merging of positions.
    func createPresentableList() -> [PresentableNeededPosition] {
        self
        .uniq(by: \.identifer)
        .sorted(by: \.positionName)
        .compactMap { (mPosition: MNeededPosition) -> PresentableNeededPosition? in
            return PresentableNeededPosition(
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
        sum.positionName = [personA, personB].commaSeparated(\.positionName)
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

/// A sort comparison function.
private func sortDateThenServiceTypeName(_ planA: PresentableFeedPlan, _ planB: PresentableFeedPlan) -> Bool {
    if planA.sortDate != planB.sortDate {
        return planA.sortDate < planB.sortDate
    } else {
        return planA.serviceTypeName < planB.serviceTypeName
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
