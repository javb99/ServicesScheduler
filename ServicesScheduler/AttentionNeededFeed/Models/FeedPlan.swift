//
//  FeedPlan.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/18/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

struct FeedPlan: Identifiable {
    var id: MPlan.ID
    var sortDate: Date
    var date: String
    var serviceTypeName: String
    var serviceTypeID: MServiceType.ID
    var neededPositions: [MNeededPosition]
    var teamMembers: [MPlanPerson]
}
