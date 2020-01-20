//
//  FeedComposer.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/19/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

class FeedComposer {
    static func createFeedController(network: PCODownloadService) -> some FeedController {
        let feedPlanService = FeedPlanService(network: network)
        let teamsService = TeamsService(network: network)
        let serviceTypesService = ServiceTypesService(network: network)
        let service = FeedService(
            network: network,
            feedPlanAdapter: FeedPlanPresentationAdapter.makePresentable,
            feedPlanService: feedPlanService.fetchFeedPlans,
            serviceTypesService: serviceTypesService.fetchServiceTypes,
            teamsService: teamsService.fetchTeams)
        let controller = ConcreteFeedController(feedService: service.fetchPlans)
        return controller
    }
}