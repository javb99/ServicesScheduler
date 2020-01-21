//
//  FeedPlanService.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

enum MultiServiceTypeFeedPlanService {
    typealias Function = (DateRange, Set<MServiceType>, @escaping Completion<[FeedPlan]>) -> ()
    
    public typealias FeedPlanService = (FeedPlanQuery, @escaping Completion<[FeedPlan]>) -> ()
    
    static func create(using implementationService: @escaping FeedPlanService) -> Function {
        return { dateRange, serviceTypes, completion in
            let groupedService = ArrayMapService(mapping: implementationService)
            let queries = serviceTypes.map { serviceType in
                FeedPlanQuery(dateRange: dateRange, serviceType: serviceType)
            }
            groupedService.fetch(queries) { result in
                completion(result.map { nestedPlans in
                    nestedPlans.flattened().sorted { a, b in a.sortDate < b.sortDate }
                })
            }
        }
    }
}

struct FeedPlanQuery: Hashable, Codable {
    var dateRange: DateRange
    var serviceType: MServiceType
}

class FeedPlanService {
    
    let network: PCODownloadService
    
    init(network: PCODownloadService) {
        self.network = network
    }
    
    func fetchFeedPlans(for query: FeedPlanQuery,
        completion: @escaping Completion<[FeedPlan]>
    ) {
        let plansInRange = Endpoints.services.serviceTypes[id: query.serviceType.identifer].plans.filter(query.dateRange)
        network.basicFetch(plansInRange) { result in
            let subGroup = DispatchGroup()
            var results = Protected([FeedPlan]())
            for plan in (result.value ?? []).prefix(4) {
                // Also wait for each plan to be populated.
                subGroup.enter()
                self.populatePlan(plan, in: query.serviceType) { feedPlanResult in
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
        let initialFeedPlan = FeedPlan(
            id: plan.identifer,
            sortDate: plan.sortDate ?? Date(),
            date: plan.shortDates ?? plan.longDates ?? "???",
            serviceTypeName: serviceType.name ?? "???",
            serviceTypeID: serviceType.identifer,
            neededPositions: [],
            teamMembers: []
        )
        
        var results = Protected(initialFeedPlan)
        
        let basePlanEndpoint = Endpoints.services
            .serviceTypes[id: serviceType.identifer]
            .plans[id: plan.identifer]
        let neededPositionsEndpoint = basePlanEndpoint.neededPositions
            .page(offset: 0, pageSize: 100)
        let teamMembersEndpoint = basePlanEndpoint.teamMembers
            .page(offset: 0, pageSize: 100)
        
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

extension Endpoints.ServiceType.PlanFilter: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .after(date):
            hasher.combine(date)
        case let .before(date):
            hasher.combine(date)
        case .future:
            hasher.combine(0)
        case .past:
            hasher.combine(1)
        case .noDates:
            hasher.combine(2)
        }
    }
    
    public static func ==(_ lhs: Self, _ rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.after(left), .after(right)),
             let (.before(left), .before(right)):
            return left == right
        case (.noDates, .noDates), (.past, .past), (.future, .future):
            return true
        default:
            return false
        }
    }
}

extension Endpoints.ServiceType.PlanFilter: Codable {
    
    enum CodingKeys: String, CodingKey {
        case value
        case date
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decode(String.self, forKey: .value)
        let date = try container.decodeIfPresent(Date.self, forKey: .date)
        switch (value, date) {
        case ("future", _):
            self = .future
        case ("past", _):
            self = .past
        case ("noDates", _):
            self = .noDates
        case ("before", let .some(endDate)):
            self = .before(endDate)
        case ("after", let .some(startDate)):
            self = .after(startDate)
        default:
            throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Unexpected value or missing date")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var value: String
        switch self {
        case .future:
            value = "future"
        case .past:
            value = "past"
        case .noDates:
            value = "noDates"
        case let .before(date):
            value = "before"
            try container.encode(date, forKey: .date)
        case let .after(date):
            value = "after"
            try container.encode(date, forKey: .date)
        }
        try container.encode(value, forKey: .value)
    }
}
