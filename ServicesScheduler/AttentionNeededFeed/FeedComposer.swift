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
    
    static func createFeedController(
        network: PCODownloadService,
        teamService: @escaping TeamService.Function,
        serviceTypeService: @escaping ServiceTypeService.Function
    ) -> some FeedController {
        
        let individualFeedPlanService = FeedPlanService(network: network).fetchFeedPlans(for:completion:)
        let cachedIndivFeedPlanService = CachedService(
            service: individualFeedPlanService,
            cache: PersistentCache.loadOrCreate(invalidationStrategy: .afterOneHour)
        ).fetch
        let feedPlanSetService = MultiServiceTypeFeedPlanService.create(using:
            cachedIndivFeedPlanService)
        
        let teamSetService = TeamSetService(mapping: teamService).fetch
        
        let serviceTypeSetService = ServiceTypeSetService(mapping: serviceTypeService).fetch
        
        let service = FeedService(
            feedPlanAdapter: FeedPlanPresentationAdapter.makePresentable,
            feedPlanService: feedPlanSetService,
            serviceTypesService: serviceTypeSetService,
            teamsService: teamSetService
        )
        
        let controller = ConcreteFeedController(feedService: service.fetchPlans)
        return controller
    }
}
