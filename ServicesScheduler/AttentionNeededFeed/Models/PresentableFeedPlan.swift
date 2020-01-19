//
//  PresentableFeedPlan.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/18/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation

/// A plan as needed by the Feed UI.
struct PresentableFeedPlan: Identifiable {
    var id: MPlan.ID
    var sortDate: Date
    var date: String
    var serviceTypeName: String
    var teams: [PresentableFeedTeam]
}

struct PresentableFeedTeam: Identifiable {
    var id: MTeam.ID
    var name: String
    var neededPostions: [PresentableNeededPosition]
    var teamMembers: [PresentableTeamMember]
}

struct PresentableNeededPosition: Identifiable {
    var id: String
    var title: String
    var count: Int
}

struct PresentableTeamMember: Identifiable {
    var id: String
    var name: String
    var position: String
    var status: PresentableStatus
    var hasUnsentNotification: Bool
}
