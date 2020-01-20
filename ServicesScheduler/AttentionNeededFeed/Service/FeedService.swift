//
//  FeedService.swift
//  ServicesSchedulerTests
//
//  Created by Joseph Van Boxtel on 1/17/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift
import JSONAPISpec

public func compose<A, B, C>(_ h: @escaping (A)->B, into g: @escaping (B)->C) -> (A)->C {
    return { a in
        g(h(a))
    }
}

extension PCODownloadService {
    func basicFetch<Endpt: Endpoint, R: ResourceProtocol>(
        _ endpoint: Endpt,
        completion: @escaping Completion<Resource<R>>
    ) where Endpt.RequestBody == JSONAPISpec.Empty, Endpt.ResponseBody == ResourceDocument<R> {
        fetch(endpoint, completion: compose(validateResult, into: completion))
    }
    
    func validateResult<Endpt: Endpoint, R: ResourceProtocol>(_ result: Result<(HTTPURLResponse, Endpt, ResourceDocument<R>), NetworkError>) -> Result<Resource<R>, Error> where Endpt.ResponseBody == ResourceDocument<R> {
        result
            .map{ (response, endpoint, body) in body.data! }
            .mapError { $0 as Error }
    }
    
    func fetchGroup<Endpt: Endpoint, R: ResourceProtocol>(
        _ endpoints: [Endpt],
        completion: @escaping Completion<[Resource<R>]>
    ) where Endpt.RequestBody == JSONAPISpec.Empty, Endpt.ResponseBody == ResourceDocument<R> {
        var results = Protected<[Resource<R>]>([])
        let group = DispatchGroup()
        endpoints.forEach { endpoint in
            group.enter()
            self.basicFetch(endpoint) { result in
                if let team = result.value {
                    results.mutate { partialResults in
                        partialResults.append(team)
                    }
                }
                group.leave()
            }
        }
        let _ = group.wait(timeout: .now() + 5)
        completion(.success(results.value))
    }
    
    func basicFetch<Endpt: Endpoint, R: ResourceProtocol>(
        _ endpoint: Endpt,
        completion: @escaping Completion<[Resource<R>]>
    ) where Endpt.RequestBody == JSONAPISpec.Empty, Endpt.ResponseBody == ResourceCollectionDocument<R> {
        fetch(endpoint, completion: compose(validateGroupResult, into: completion))
    }
    
    func validateGroupResult<Endpt: Endpoint, R: ResourceProtocol>(_ result: Result<(HTTPURLResponse, Endpt, ResourceCollectionDocument<R>), NetworkError>) -> Result<[Resource<R>], Error> where Endpt.ResponseBody == ResourceCollectionDocument<R> {
        result
            .map{ (response, endpoint, body) in body.data! }
            .mapError { $0 as Error }
    }
    
    func fetchGroup<Endpt: Endpoint, R: ResourceProtocol>(
        _ endpoints: [Endpt],
        completion: @escaping Completion<[Resource<R>]>
    ) where Endpt.RequestBody == JSONAPISpec.Empty, Endpt.ResponseBody == ResourceCollectionDocument<R> {
        var results = Protected<[Resource<R>]>([])
        let group = DispatchGroup()
        endpoints.forEach { endpoint in
            group.enter()
            self.basicFetch(endpoint) { result in
                if let success = result.value {
                    results.mutate { partialResults in
                        partialResults.append(contentsOf: success)
                    }
                }
                group.leave()
            }
        }
        let _ = group.wait(timeout: .now() + 5)
        completion(.success(results.value))
    }
}

extension Collection where Element: Hashable {
    func asSet() -> Set<Element> {
        Set(self)
    }
}

enum FeedError: Error {
    case timeout(message: String)
}

class FeedService {
    
    let network: PCODownloadService
    
    typealias FeedPlanAdapter = (FeedPlan, Set<MTeam>) -> PresentableFeedPlan
    let feedPlanAdapter: FeedPlanAdapter
    
    init(network: PCODownloadService, feedPlanAdapter: @escaping FeedPlanAdapter) {
        self.network = network
        self.feedPlanAdapter = feedPlanAdapter
    }
    
    func fetchPlans(
        in dateRange: DateRange,
        forTeams teamIDs: Set<MTeam.ID>,
        completion: @escaping Completion<[PresentableFeedPlan]>
    ) {
        DispatchQueue.global().async {
            self.syncFetchPlans(in: dateRange, forTeams: teamIDs) { result in
                completion(result)
            }
        }
    }
    
    func syncFetchPlans(
        in dateRange: DateRange,
        forTeams teamIDs: Set<MTeam.ID>,
        completion: @escaping Completion<[PresentableFeedPlan]>
    ) {
        func fail(_ error: Error) {
            print("Failing FeedPlanService: \(error)")
            completion(.failure(error))
        }
        print("Starting to fetch plans")
        let semaphore = DispatchSemaphore(value: 0)
        
        var teamsResult: Result<Set<MTeam>, Error>?
        fetchTeams(teamIDs) { result in
            teamsResult = result
            semaphore.signal()
        }
        print("Waiting for fetching teams")
        let _ = semaphore.wait(timeout: .now() + 5)
        print("Finished to fetching teams")
        guard let teams = teamsResult?.value else {
            if let error = teamsResult?.error {
                fail(error)
            } else {
                fail(FeedError.timeout(message: "fetchTeams timed out"))
            }
            return
        }
        
        var serviceTypesResult: Result<Set<MServiceType>, Error>?
        fetchServiceTypes(self.serviceTypeIDs(for: teams)) { result in
            serviceTypesResult = result
            semaphore.signal()
        }
        print("Waiting for fetching service types")
        let _ = semaphore.wait(timeout: .now() + 5)
        print("Finished to fetching service types")
        guard let serviceTypes = serviceTypesResult?.value else {
            if let error = serviceTypesResult?.error {
                fail(error)
            } else {
                fail(FeedError.timeout(message: "fetchServiceTypes timed out"))
            }
            return
        }
        
        var feedPlansResult: Result<[FeedPlan], Error>?
        feedPlans(in: dateRange, forServiceTypes: serviceTypes) { result in
            feedPlansResult = result
            semaphore.signal()
        }
        print("Waiting for fetching feed plans")
        let _ = semaphore.wait(timeout: .now() + 5)
        
        guard let feedPlans = feedPlansResult?.value else {
            if let error = feedPlansResult?.error {
                fail(error)
            } else {
                fail(FeedError.timeout(message: "fetchFeedPlans timed out"))
            }
            return
        }
        print("Finished to fetching feed plans: \(feedPlans)")
        
        let presentablePlans = feedPlans.map { feedPlan in
            modelToPresentationPlanAdapter(feedPlan, teams)
        }
        completion(.success(presentablePlans))
    }
    
    func modelToPresentationPlanAdapter(_ feedPlan: FeedPlan, _ allFetchedTeams: Set<MTeam>) -> PresentableFeedPlan {
        return self.feedPlanAdapter(feedPlan, allFetchedTeams)
    }
    
    func feedPlans(
        in dateRange: DateRange,
        forServiceTypes serviceTypes: Set<MServiceType>,
        completion: @escaping Completion<[FeedPlan]>
    ) {
        let group = DispatchGroup()
        var results = Protected(Array<FeedPlan>())
        serviceTypes.forEach { serviceType in
            let plansInRange = Endpoints.services.serviceTypes[id: serviceType.identifer].plans.filter(dateRange)
            group.enter()
            network.basicFetch(plansInRange) { result in
                let subGroup = DispatchGroup()
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
                    group.leave()
                }
            }
        }
        
        let _ = group.wait()
        results.mutate {
            $0.sort{ a, b in a.sortDate < b.sortDate }
        }
        completion(.success(results.value))
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
    
    func serviceTypeIDs(for teams: Set<MTeam>) -> Set<MServiceType.ID> {
        let ids = teams.compactMap{ team in team.serviceType.data }
        return Set(ids)
    }
    
    func fetchServiceTypes(
        _ serviceTypeIDs: Set<MServiceType.ID>,
        completion: @escaping Completion<Set<MServiceType>>
    ) {
        let endpoints = serviceTypeIDs.map { serviceTypeID in
            Endpoints.services.serviceTypes[id: serviceTypeID]
        }
        network.fetchGroup(endpoints) { result in
            completion(result.map { $0.asSet() })
        }
    }
    
    func fetchTeams(
        _ teamIDs: Set<MTeam.ID>,
        completion: @escaping Completion<Set<MTeam>>
    ) {
        let endpoints = teamIDs.map { teamID in Endpoints.services.teams[id: teamID] }
        network.fetchGroup(endpoints) { result in
            completion(result.map { $0.asSet() })
        }
    }
}

typealias DateRange = [Endpoints.ServiceType.PlanFilter]

public typealias UserFacingError = Error
