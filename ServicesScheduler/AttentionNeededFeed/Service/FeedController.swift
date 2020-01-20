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
    
    var canLoadMorePlans: Bool { true }
    
    private var teams: Set<MTeam.ID> = []
    
    func loadMorePlans() {
        loadInDateRange([.past], teams) { result in
            DispatchQueue.main.async {
                if let newPlans = result.value {
                    self.plans.append(contentsOf: newPlans)
                    self.plans.sort { $0.sortDate < $1.sortDate }
                }
            }
        }
    }
    
    func reset(for teams: Set<MTeam.ID>) {
        plans.removeAll()
        self.teams = teams
        loadInDateRange([.future], teams) { result in
            DispatchQueue.main.async {
                if let newPlans = result.value {
                    self.plans = newPlans
                }
            }
        }
    }
}

class FeedComposer {
    static func createFeedController(network: PCODownloadService) -> some FeedController {
        let service = FeedService(network: network, feedPlanAdapter: FeedPlanPresentationAdapter.makePresentable)
        let controller = ConcreteFeedController(feedService: service.fetchPlans)
        return controller
    }
}
