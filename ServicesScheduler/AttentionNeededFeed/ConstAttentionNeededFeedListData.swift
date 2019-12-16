//
//  ConstAttentionNeededFeedListData.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/5/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

class ConstAttentionNeededFeedListData: AttentionNeededFeedDataSource {
    
    init(_ data: [(Plan, [(Team, ([NeededPosition], [TeamMember]))])]) {
        self.plans = data.map{$0.0}
        let teamTuplesByPlan = Dictionary(uniqueKeysWithValues: data.map{ ($0.0.id, $0.1) })
        self.teams = teamTuplesByPlan.mapValues { $0.map{ team in team.0 }}
        let teamContent = teamTuplesByPlan.mapValues { teamTuple in Dictionary(uniqueKeysWithValues: teamTuple.map{ ($0.0.id, $0.1) }) }
        self.neededPositions = teamContent.mapValues { $0.mapValues{ content in content.0 } }
        self.teamMembers = teamContent.mapValues { $0.mapValues{ content in content.1 } }
    }
    
    @Published var plans: [Plan]
    @Published var teams: [Plan.ID: [Team]]
    @Published var neededPositions: [Plan.ID: [Team.ID: [NeededPosition]]]
    @Published var teamMembers: [Plan.ID: [Team.ID: [TeamMember]]]
    
    func teams(plan: Plan) -> [Team] {
        teams[plan.id] ?? []
    }
    
    func neededPositions(plan: Plan, team: Team) -> [NeededPosition] {
        neededPositions[plan.id]?[team.id] ?? []
    }
    
    func teamMembers(plan: Plan, team: Team) -> [TeamMember] {
        teamMembers[plan.id]?[team.id] ?? []
    }
}

extension ConstAttentionNeededFeedListData {
    static let sample = ConstAttentionNeededFeedListData([
        (
            Plan(
                id: "1",
                date: "Sunday Aug. 12",
                serviceTypeName: "Vancouver - Services - Weekend"
            ),
            [
                (
                    Team("Band", id: "1"),
                    (
                        [
                            NeededPosition(
                                id: "1",
                                title: "Drums",
                                count: 1
                            )
                        ],
                        [
                            TeamMember(
                                id: "1",
                                name: "Joseph Van Boxtel",
                                position: "Music Director",
                                status: .confirmed
                            )
                        ]
                    )
                ),
                (
                    Team("Tech", id: "2"),
                    (
                        [
                            NeededPosition(
                                id: "1",
                                title: "Front Of House",
                                count: 1
                            )
                        ],
                        [
                            TeamMember(
                                id: "2",
                                name: "Remington Smith",
                                position: "Head Hancho",
                                status: .confirmed
                            )
                        ]
                    )
                )
            ]
        )
    ])
}
