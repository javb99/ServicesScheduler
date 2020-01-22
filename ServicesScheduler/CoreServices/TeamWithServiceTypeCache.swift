//
//  TeamWithServiceTypeCache.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/21/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

class TeamWithServiceTypeCache<TeamCache, ServiceTypeCache> : AsyncCache where
    TeamCache: AsyncCache,
    ServiceTypeCache: AsyncCache,
    TeamCache.Key == MTeam.ID,
    TeamCache.Value == MTeam,
    ServiceTypeCache.Key == MServiceType.ID,
ServiceTypeCache.Value == MServiceType {
    
    typealias Key = MTeam.ID
    typealias Value = TeamWithServiceType
    
    var teamCache: TeamCache
    var serviceTypeCache: ServiceTypeCache
    
    internal init(teamCache: TeamCache, serviceTypeCache: ServiceTypeCache) {
        self.teamCache = teamCache
        self.serviceTypeCache = serviceTypeCache
    }
    
    /// Wraps the service and stores the results in the caches.
    func recordResults(of service: @escaping TeamWithServiceTypeService) -> TeamWithServiceTypeService {
        return { teamID, completion in
            service(teamID) { result in
                if let teamWithServiceType = result.value {
                    self.teamCache.setCached(teamWithServiceType.team, for: teamID)
                    let serviceType = teamWithServiceType.serviceType
                    self.serviceTypeCache.setCached(serviceType, for: serviceType.identifer)
                }
                completion(result)
            }
        }
    }
    
    func setCached(_ value: TeamWithServiceType, for key: MTeam.ID) {
        teamCache.setCached(value.team, for: key)
        serviceTypeCache.setCached(value.serviceType, for: value.serviceType.identifer)
    }
    
    func getCachedValue(for key: MTeam.ID, completion: @escaping (TeamWithServiceType?) -> ()) {
        teamCache.getCachedValue(for: key) { teamOrNil in
            guard let team = teamOrNil,
                let serviceTypeID = team.serviceType.data else {
                    print("No Team for \(key.id)")
                completion(nil)
                return
            }
            self.serviceTypeCache.getCachedValue(for: serviceTypeID) { serviceTypeOrNil in
                guard let serviceType = serviceTypeOrNil else {
                    print("No ServiceType for \(serviceTypeID.id)")
                    completion(nil)
                    return
                }
                print("Found TeamWithServiceType for \(key.id) - \(team.name!) (\(serviceType.name!))")
                completion(
                    TeamWithServiceType(team: team, serviceType: serviceType)
                )
            }
        }
    }
}
