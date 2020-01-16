//
//  ConstAttentionNeededFeedListData.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/5/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

class ConstAttentionNeededFeedListData: AttentionNeededFeedDataSource {
    
    init(_ data: [(Plan, [PresentableFeedTeam])]) {
        self.plans = data.map{$0.0}
        self.teams = Dictionary(uniqueKeysWithValues: data.map{ ($0.0.id, $0.1) })
    }
    
    @Published var plans: [Plan]
    @Published var teams: [Plan.ID: [PresentableFeedTeam]]
    
    func teams(plan: Plan) -> [PresentableFeedTeam] {
        teams[plan.id] ?? []
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
                PresentableFeedTeam(id: "1", name: "Band", neededPostions: [
                        PresentableNeededPosition(
                            id: "1",
                            title: "Drums",
                            count: 1
                        )
                    ],
                    teamMembers: [
                        PresentableTeamMember(
                            id: "1",
                            name: "Joseph Van Boxtel",
                            position: "Music Director",
                            status: .confirmed,
                            hasUnsentNotification: false
                        )
                    ]
                ),
                PresentableFeedTeam(
                    id: "2",
                    name: "Tech",
                    neededPostions: [
                        PresentableNeededPosition(
                            id: "1",
                            title: "Front Of House",
                            count: 1
                        )
                    ],
                    teamMembers: [
                        PresentableTeamMember(
                            id: "2",
                            name: "Remington Smith",
                            position: "Head Hancho",
                            status: .confirmed,
                            hasUnsentNotification: true
                        )
                    ]
                )
            ]
        )
    ])
}
