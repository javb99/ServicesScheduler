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
    static func createFeedController<TeamCache, ServiceTypeCache>(network: PCODownloadService, teamCache: TeamCache, serviceTypeCache: ServiceTypeCache) -> some FeedController where
        TeamCache: AsyncCache,
        TeamCache.Value == MTeam,
        TeamCache.Key == MTeam.ID,
        ServiceTypeCache: AsyncCache,
        ServiceTypeCache.Value == MServiceType,
        ServiceTypeCache.Key == MServiceType.ID {
        
        let individualFeedPlanService = FeedPlanService(network: network).fetchFeedPlans(for:completion:)
        let cachedIndivFeedPlanService = CachedService(
            service: individualFeedPlanService,
            cache: PersistentCache.loadOrCreate(invalidationStrategy: .afterOneHour)
        ).fetch
        let feedPlanSetService = MultiServiceTypeFeedPlanService.create(using:
            cachedIndivFeedPlanService)
        
        let teamService = CachedService(
            service: TeamService.create(using: network),
            cache: teamCache
        ).fetch
        let teamSetService = TeamSetService(mapping: teamService).fetch
        
        let serviceTypeService = CachedService(
            service: ServiceTypeService.create(using: network),
            cache: serviceTypeCache
        ).fetch
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
