//
//  AttentionNeededListLoader.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/5/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Combine
import Foundation
import JSONAPISpec
import PlanningCenterSwift

extension Resource {
    public typealias ID = ResourceIdentifier<Type>
}

public typealias MServiceType = Resource<Models.ServiceType>
public typealias MPlan = Resource<Models.Plan>
public typealias MPlanPerson = Resource<Models.PlanPerson>
public typealias MNeededPosition = Resource<Models.NeededPosition>

class AttentionNeededListLoader {
    init(network: URLSessionService) {
        self.network = network
    }
    
    let network: URLSessionService
    
    @Published var teams: [MServiceType.ID: [MTeam]] = [:] {
        didSet {
            print("Teams: " + teams.values.flatMap { $0 }.commaSeparated(\.name))
        }
    }
    
    @Published var serviceTypes: [MServiceType] = [] {
        didSet {
            print("Service Types: " + serviceTypes.commaSeparated(\.name))
        }
    }
    
    @Published var plans: [MPlan] = [] {
        didSet {
            print("Plans: " + plans.commaSeparated(\.shortDates))
        }
    }
    
    @Published var planPeople: [MPlanPerson] = [] {
        didSet {
            let peopleNames = planPeople.map { $0.name + "-" + $0.status.rawValue }.commaSeparated(\.self)
            print("\(planPeople.count) Plan People: " + peopleNames)
        }
    }
    
    @Published var neededPositions: [MNeededPosition] = [] {
        didSet {
            print("\(neededPositions.count) NeededPositions")
        }
    }
    
    var currentLoad: AnyCancellable?
    
    func load(teams: Set<Team.ID>) {
        self.teams.removeAll()
        plans.removeAll()
        serviceTypes.removeAll()
        planPeople.removeAll()
        neededPositions.removeAll()
        
        currentLoad?.cancel()
        let plansPublisher = Publishers.Sequence(sequence: teams)
            .setFailureType(to: NetworkError.self)
            .flatMap { self.teamPublisher(team: $0) }
            .handleEvents(receiveOutput: { mTeam in
                guard let serviceTypeID = mTeam.serviceType.data else { return }
                DispatchQueue.main.async {
                    self.teams.appendOrInitialize(mTeam, for: serviceTypeID)
                }
            })
            .compactMap { mTeam in mTeam.serviceType.data }
            .flatMap { serviceTypeID in
                self.serviceTypesPublisher(serviceType: serviceTypeID.id)
            }
            .handleEvents(receiveOutput: { (serviceType: MServiceType) in
                DispatchQueue.main.async {
                    self.serviceTypes.append(serviceType)
                }
            })
            .flatMap { serviceType in
                Just(serviceType).setFailureType(to: NetworkError.self)
                    .combineLatest(
                        self.futurePlansPublisher(forServiceType: serviceType.identifer.id)
                            .prefix(4)
                            .handleEvents(receiveOutput: { (plan: MPlan) in
                                DispatchQueue.main.async {
                                    self.plans.append(plan)
                                }
                            })
                    )
            }.eraseToAnyPublisher()
        let peopleSub = plansPublisher
            .flatMap { (both: (MServiceType, MPlan)) in
                self.teamMembersPublisher(forServiceType: both.0.identifer.id, planID: both.1.identifer)
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { self.planPeople.append(contentsOf: $0) }
        
        let positionsSub = plansPublisher
            .flatMap { (both: (MServiceType, MPlan)) in
                self.neededPositionsPublisher(forServiceType: both.0.identifer.id, planID: both.1.identifer)
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { self.neededPositions.append(contentsOf: $0) }
        
        currentLoad = AnyCancellable {
            peopleSub.cancel()
            positionsSub.cancel()
        }
    }
    
    func teamPublisher(team: String) -> AnyPublisher<MTeam, NetworkError> {
        let id = MTeam.ID(stringLiteral: team)
        let endpoint = Endpoints.services.teams[id: id]
        return network.future(for: endpoint)
            .map(\.2.data)
            .compactMap(identity)
            .eraseToAnyPublisher()
    }
    
    func serviceTypesPublisher(serviceType: String) -> AnyPublisher<MServiceType, NetworkError> {
        let id = MServiceType.ID(stringLiteral: serviceType)
        let endpoint = Endpoints.services.serviceTypes[id: id]
        return network.future(for: endpoint)
            .map(\.2.data)
            .compactMap(identity)
            .eraseToAnyPublisher()
    }
    
    func futurePlansPublisher(forServiceType serviceType: String) -> AnyPublisher<MPlan, NetworkError> {
        let id = MServiceType.ID(stringLiteral: serviceType)
        let endpoint = Endpoints.services.serviceTypes[id: id].plans.filter(.future)
        return network.publisher(for: endpoint)
            .eraseToAnyPublisher()
    }
    
    func teamMembersPublisher(forServiceType serviceTypeID: String, planID: MPlan.ID) -> AnyPublisher<[MPlanPerson], NetworkError> {
        let serviceID = MServiceType.ID(stringLiteral: serviceTypeID)
        let membersEndpoint = Endpoints.services.serviceTypes[id: serviceID].plans[id: planID].teamMembers
        return network.publisher(for: membersEndpoint)
            .collect()
            .eraseToAnyPublisher()
    }
    
    func neededPositionsPublisher(forServiceType serviceTypeID: String, planID: MPlan.ID) -> AnyPublisher<[MNeededPosition], NetworkError> {
        let serviceID = MServiceType.ID(stringLiteral: serviceTypeID)
        let endpoint = Endpoints.services.serviceTypes[id: serviceID].plans[id: planID].neededPositions
        return network.publisher(for: endpoint)
            .collect()
            .handleEvents(receiveCompletion: { print("NeededPositions.complete: \($0)") }, receiveCancel: { print("NeededPositions.cancel") })
            .eraseToAnyPublisher()
    }
}

extension Dictionary where Value: RangeReplaceableCollection, Value: ExpressibleByArrayLiteral {
    /// Append an element or initialize with a single element collection with the value at the given key.
    mutating func appendOrInitialize(_ element: Value.Element, for key: Key) {
        if self[key] != nil {
            self[key]!.append(element)
        } else {
            self[key] = Value([element])
        }
    }
}
