//
//  FeedController.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/17/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

class ConcreteFeedController: FeedController {
    
    init(feedService: @escaping ConcreteFeedController.FeedService) {
        self.loadInDateRange = feedService
    }
    
    typealias FeedService = (DateRange, Set<MTeam.ID>, @escaping UserCompletion<[PresentableFeedPlan]>)->()
    let loadInDateRange: FeedService
    
    @Published var plans: [PresentableFeedPlan] = []
    
    @Published var isLoading: Bool = false
    
    var canLoadMorePlans: Bool { true }
    
    private var teams: Set<MTeam.ID> = []
    
    func loadMorePlans() {
        isLoading = true
        loadInDateRange([.past], teams) { result in
            DispatchQueue.main.async {
                if let newPlans = result.value {
                    self.plans.append(contentsOf: newPlans)
                    self.plans.sort { $0.sortDate < $1.sortDate }
                }
                self.isLoading = false
            }
        }
    }
    
    func reset(for teams: Set<MTeam.ID>) {
        self.teams = teams
        isLoading = true
        loadInDateRange([.future], teams) { result in
            DispatchQueue.main.async {
                if let newPlans = result.value {
                    self.plans = newPlans
                }
                self.isLoading = false
            }
        }
    }
}
