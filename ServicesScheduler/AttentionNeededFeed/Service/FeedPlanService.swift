//
//  FeedPlanService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

class FeedPlanService {
    
    let network: PCODownloadService
    
    init(network: PCODownloadService) {
        self.network = network
    }
    
    func fetchFeedPlans(
        in dateRange: DateRange,
        forServiceTypes serviceTypes: Set<MServiceType>,
        completion: @escaping Completion<[FeedPlan]>
    ) {
        let group = DispatchGroup()
        var results = Protected(Array<FeedPlan>())
        serviceTypes.forEach { serviceType in
            group.enter()
            self.fetchFeedPlans(in: dateRange, for: serviceType) { result in
                if let plansForServiceType = result.value {
                    results.mutate { $0.append(contentsOf: plansForServiceType) }
                }
                group.leave()
            }
        }
        
        let _ = group.wait()
        results.mutate {
            $0.sort{ a, b in a.sortDate < b.sortDate }
        }
        completion(.success(results.value))
    }
    
    func fetchFeedPlans(
        in dateRange: DateRange,
        for serviceType: MServiceType,
        completion: @escaping Completion<[FeedPlan]>
    ) {
        let plansInRange = Endpoints.services.serviceTypes[id: serviceType.identifer].plans.filter(dateRange)
        network.basicFetch(plansInRange) { result in
            let subGroup = DispatchGroup()
            var results = Protected([FeedPlan]())
            for plan in (result.value ?? []).prefix(4) {
                // Also wait for each plan to be populated.
                subGroup.enter()
                self.populatePlan(plan, in: serviceType) { feedPlanResult in
                    if let feedPlan = feedPlanResult.value {
                        results.mutate { $0.append(feedPlan) }
                    }
                    subGroup.leave()
                }
            }
            subGroup.notify(queue: .global()) {
                completion(.success(results.value))
            }
        }
    }
    
    func populatePlan(
        _ plan: MPlan,
        in serviceType: MServiceType,
        completion: @escaping Completion<FeedPlan>
    ) {
        let group = DispatchGroup()
        let initialFeedPlan = FeedPlan(id: plan.identifer,
                                       sortDate: plan.sortDate ?? Date(),
                                       date: plan.shortDates ?? plan.longDates ?? "???",
                                       serviceTypeName: serviceType.name ?? "???",
                                       serviceTypeID: serviceType.identifer,
                                       neededPositions: [], teamMembers: [])
        
        var results = Protected(initialFeedPlan)
        
        let neededPositionsEndpoint = Endpoints.services.serviceTypes[id: serviceType.identifer].plans[id: plan.identifer].neededPositions.page(offset: 0, pageSize: 100)
        
        let teamMembersEndpoint = Endpoints.services.serviceTypes[id: serviceType.identifer].plans[id: plan.identifer].teamMembers.page(offset: 0, pageSize: 100)
        
        group.enter()
        network.basicFetch(neededPositionsEndpoint) { result in
            if let modelNeededPositions = result.value {
                results.mutate { partialFeedPlan in
                    partialFeedPlan.neededPositions = modelNeededPositions
                }
            }
            group.leave()
        }
        
        group.enter()
        network.basicFetch(teamMembersEndpoint) { result in
            if let modelTeamMembers = result.value {
                results.mutate { partialFeedPlan in
                    partialFeedPlan.teamMembers = modelTeamMembers
                }
            }
            group.leave()
        }
        
        group.notify(queue: .global()) {
            completion(.success(results.value))
        }
    }
}
