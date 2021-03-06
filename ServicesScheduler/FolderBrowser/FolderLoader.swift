//
//  FolderLoader.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import Combine
import PlanningCenterSwift
import JSONAPISpec

class FolderLoader: FolderContentProvider {
    
    let network: URLSessionService
    let parent: Resource<Models.Folder>?
    
    init(network: URLSessionService, parent: Resource<Models.Folder>? = nil) {
        self.network = network
        self.parent = parent
    }
    
    var folders: [Resource<Models.Folder>] = [] {
        willSet {
            objectWillChange.send()
        }
        didSet {
            folderNames = folders.map{ .init($0.name!, id: $0.identifer.id) }
        }
    }
    
    var serviceTypes: [Resource<Models.ServiceType>] = [] {
        willSet {
            objectWillChange.send()
        }
        didSet {
            serviceTypeNames = serviceTypes.map{ .init($0.name!, id: $0.identifer.id) }
        }
    }
    
    func folder(for presentableFolder: PresentableFolder) -> Resource<Models.Folder>? {
        folders.first(where: {$0.identifer.id == presentableFolder.id})
    }
    
    func serviceType(for presentableServiceType: PresentableServiceType) -> Resource<Models.ServiceType>? {
        serviceTypes.first(where: {$0.identifer.id == presentableServiceType.id})
    }
    
    var folderNames: [PresentableFolder] = []
    
    var serviceTypeNames: [PresentableServiceType] = [] {
        willSet {
            objectWillChange.send()
        }
    }
    
    func load() {
        if let parent = parent {
            let baseFolderEndpoint = Endpoints.services.folders[id: parent.identifer]
            network.fetch(baseFolderEndpoint.subfolders, completion: self.handleLoadResult)
            network.fetch(baseFolderEndpoint.serviceTypes, completion: self.handleServiceTypesLoadResult)
        } else {
            network.fetch(Endpoints.services.rootFolders, completion: self.handleLoadResult)
            network.fetch(Endpoints.services.rootServiceTypes, completion: self.handleServiceTypesLoadResult)
        }
    }
    
    private func handleLoadResult<Endpt: Endpoint>(_ result: Result<(HTTPURLResponse, Endpt, Endpt.ResponseBody), NetworkError>) where Endpt.ResponseBody == ResourceCollectionDocument<Models.Folder> {
        DispatchQueue.main.async {
            
            switch result {
            case let .success(_, _, document):
                self.folders = document.data ?? []
            case let .failure(error):
                self.folders = []
            }
        }
    }
    
    private func handleServiceTypesLoadResult<Endpt: Endpoint>(_ result: Result<(HTTPURLResponse, Endpt, Endpt.ResponseBody), NetworkError>) where Endpt.ResponseBody == ResourceCollectionDocument<Models.ServiceType> {
        DispatchQueue.main.async {
            
            switch result {
            case let .success(_, _, document):
                self.serviceTypes = document.data ?? []
            case let .failure(error):
                self.serviceTypes = []
            }
        }
    }
    
    var objectWillChange = PassthroughSubject<Void, Never>()
}
