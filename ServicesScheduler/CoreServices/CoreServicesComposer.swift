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
    /// MARK: Caching
    lazy var teamCache = PersistentCache<MTeam.ID, MTeam>.loadOrCreate(name: "Team")
    lazy var serviceTypeCache = PersistentCache<MServiceType.ID, MServiceType>.loadOrCreate(name: "ServiceType")
    
    lazy var teamWithServiceTypeCache = TeamWithServiceTypeCache(
        teamCache: self.teamCache,
        serviceTypeCache: self.serviceTypeCache
    )
    var observeTeamWithServiceTypeService: (@escaping TeamWithServiceTypeService)->TeamWithServiceTypeService { teamWithServiceTypeCache.recordResults(of:) }
}
