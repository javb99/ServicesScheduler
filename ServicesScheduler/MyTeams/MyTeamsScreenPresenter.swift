//
//  MyTeamsScreenPresenter.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 11/11/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift
import JSONAPISpec

final class MyTeamsScreenPresenter: MyTeamsScreenModel {
    
    let myTeamsService: MyTeamsService
    
    init(myTeamsService: MyTeamsService) {
        self.myTeamsService = myTeamsService
    }
    
    @Published var myTeams: [ServiceTypeTeams] = []
    
    @Published var isLoadingMyTeams: Bool = false
    
    @Published var selectedTeams: Set<Team.ID> = []
    
    func teamScreenDidAppear() {
        let shouldAvoidReload = !myTeams.isEmpty || isLoadingMyTeams
        if shouldAvoidReload { return }
        
        isLoadingMyTeams = true
        
        myTeamsService.load() { result in
            DispatchQueue.main.async {
                self.isLoadingMyTeams = false
                
                if let teams = try? result.get() {
                    self.processTeams(teams)
                } else {
                    print("Failed \(result)")
                }
            }
        }
    }
    
    fileprivate func processTeams(_ teams: [TeamWithServiceType]) {
        let teamsByServiceType = teams.group(by: \.serviceType.identifer)
        let serviceTypes = teams.pluck(\.serviceType).uniq(by: \.identifer).filter{ $0.name != nil }.sortedLexographically(on: \.name!)
        let teamsForServiceType = serviceTypes.compactMap { serviceType -> ServiceTypeTeams? in
            
            guard let thisTeams = teamsByServiceType[serviceType.identifer]?
                .pluck(\.team)
                .compactMap(MTeam.presentableTeam)
                .sortedLexographically(on: \.name)
            else { return nil }
            if thisTeams.isEmpty { return nil }
            return ServiceTypeTeams(serviceType: serviceType.makePresentable(), teams: thisTeams)
        }
        
        self.myTeams = teamsForServiceType
    }
}

extension Resource where Type == Models.ServiceType {
    func makePresentable() -> PresentableServiceType {
        Identified(self.name ?? "Unnamed", id: identifer.id)
    }
}

extension Sequence {
    func sortedLexographically(on keyPath: KeyPath<Element, String>) -> [Element] {
        return sorted(by: {$0[keyPath: keyPath] < $1[keyPath: keyPath]})
    }
}

extension Sequence {
    func pluck<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return map{ $0[keyPath: keyPath] }
    }
}
