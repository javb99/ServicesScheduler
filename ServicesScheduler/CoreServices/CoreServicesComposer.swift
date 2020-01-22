//
//  CoreServicesComposer.x.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/21/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

class CoreServicesComposer {
    
    let network: PCODownloadService
    
    init(network: PCODownloadService) {
        self.network = network
    }
    
    /// MARK: Caching
    lazy var teamCache = PersistentCache<MTeam.ID, MTeam>.loadOrCreate(name: "Team")
    lazy var serviceTypeCache = PersistentCache<MServiceType.ID, MServiceType>.loadOrCreate(name: "ServiceType")
    
    lazy var teamWithServiceTypeCache = TeamWithServiceTypeCache(
        teamCache: self.teamCache,
        serviceTypeCache: self.serviceTypeCache
    )
    var observeTeamWithServiceTypeService: (@escaping TeamWithServiceTypeService)->TeamWithServiceTypeService { teamWithServiceTypeCache.recordResults(of:) }
    
    /// MARK: Networking
    
    lazy var teamService: TeamService.Function = CachedService(
        service: TeamService.create(using: network),
        cache: teamCache
    ).fetch
    
    lazy var serviceTypeService: ServiceTypeService.Function = CachedService(
        service: ServiceTypeService.create(using: network),
        cache: serviceTypeCache
    ).fetch
}
