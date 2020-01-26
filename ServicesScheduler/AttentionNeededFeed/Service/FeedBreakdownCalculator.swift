//
//  FeedBreakdownCalculator.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/24/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation

protocol FeedBreakdownProvider {
    func getBreakdown(plans: [PresentableFeedPlan]) -> FeedBreakdown?
}

class ArrayFeedBreakdownCalculator: FeedBreakdownProvider {
    
    func getBreakdown(plans: [PresentableFeedPlan]) -> FeedBreakdown? {
        if plans.isEmpty { return nil }
        
        let allPeople = plans.flatMap { plan in
            plan.teams.flatMap { $0.teamMembers }
        }
        let allNeeded = plans.flatMap { plan in
            plan.teams.flatMap { $0.neededPostions }
        }
        let confirmed = allPeople.count { $0.status == .confirmed }
        let unconfirmed = allPeople.count { $0.status == .unconfirmed }
        let declined = allPeople.count { $0.status == .declined }
        let unsent = allPeople.count { $0.hasUnsentNotification }
        let needed = allNeeded.count
        
        return FeedBreakdown(confirmed: confirmed, unconfirmed: unconfirmed, declined: declined, needed: needed, unsent: unsent)
    }
}

extension Sequence {
    func count(where predicate: (Element)->Bool) -> Int {
        filter(predicate).count
    }
}
