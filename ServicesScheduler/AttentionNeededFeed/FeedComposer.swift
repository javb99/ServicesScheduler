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
        
        let teamService = CachedService(
            service: TeamService.create(using: network),
            cache: InMemoryCache()
        ).fetch
        let teamSetService = TeamSetService(mapping: teamService).fetch
        
        let serviceTypesService = ServiceTypesService(network: network)
        
        let service = FeedService(
            feedPlanAdapter: FeedPlanPresentationAdapter.makePresentable,
            feedPlanService: feedPlanService.fetchFeedPlans,
            serviceTypesService: serviceTypesService.fetchServiceTypes,
            teamsService: teamSetService
        )
        
        let controller = ConcreteFeedController(feedService: service.fetchPlans)
        return controller
    }
}
