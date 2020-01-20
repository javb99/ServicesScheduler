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
    
    typealias FeedPlanService = (DateRange, Set<MServiceType>, @escaping Completion<[FeedPlan]>) -> ()
    let feedPlanService: FeedPlanService
    
    typealias ServiceTypesService = (Set<MServiceType.ID>, @escaping Completion<Set<MServiceType>>)->()
    let serviceTypesService: ServiceTypesService
    
    typealias TeamsService = (Set<MTeam.ID>, @escaping Completion<Set<MTeam>>)->()
    let teamsService: TeamsService
    
    init(network: PCODownloadService,
         feedPlanAdapter: @escaping FeedPlanAdapter,
         feedPlanService: @escaping FeedPlanService,
         serviceTypesService: @escaping ServiceTypesService,
         teamsService: @escaping TeamsService
    ) {
        self.network = network
        self.feedPlanAdapter = feedPlanAdapter
        self.feedPlanService = feedPlanService
        self.serviceTypesService = serviceTypesService
        self.teamsService = teamsService
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
        fetchFeedPlans(in: dateRange, forServiceTypes: serviceTypes) { result in
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
    
    func fetchFeedPlans(
        in dateRange: DateRange,
        forServiceTypes serviceTypes: Set<MServiceType>,
        completion: @escaping Completion<[FeedPlan]>
    ) {
        self.feedPlanService(dateRange, serviceTypes, completion)
    }
    
    func serviceTypeIDs(for teams: Set<MTeam>) -> Set<MServiceType.ID> {
        let ids = teams.compactMap{ team in team.serviceType.data }
        return Set(ids)
    }
    
    func fetchServiceTypes(
        _ serviceTypeIDs: Set<MServiceType.ID>,
        completion: @escaping Completion<Set<MServiceType>>
    ) {
        serviceTypesService(serviceTypeIDs, completion)
    }
    
    func fetchTeams(
        _ teamIDs: Set<MTeam.ID>,
        completion: @escaping Completion<Set<MTeam>>
    ) {
        teamsService(teamIDs, completion)
    }
}

typealias DateRange = [Endpoints.ServiceType.PlanFilter]

public typealias UserFacingError = Error
