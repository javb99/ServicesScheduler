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
    
    internal init(network: URLSessionService, parent: Resource<Models.Folder>? = nil) {
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
    
    func folder(for presentableFolder: PresentableFolder) -> Resource<Models.Folder>? {
        folders.first(where: {$0.identifer.id == presentableFolder.id})
    }
    
    var folderName: String {
        parent?.name ?? ""
    }
    
    var folderNames: [PresentableFolder] = []
    
    var serviceTypeNames: [PresentableServiceType] = [] {
        willSet {
            objectWillChange.send()
        }
    }
    
    func load() {
        if let parent = parent {
            print("Fetching contents of: \(parent.name!) \(parent.identifer.id)")
            let baseFolderEndpoint = Endpoints.folders[id: parent.identifer]
            network.fetch(baseFolderEndpoint.subfolders, completion: self.handleLoadResult)
            network.fetch(baseFolderEndpoint.serviceTypes, completion: self.handleServiceTypesLoadResult)
        } else {
            print("Fetching folders")
            network.fetch(Endpoints.folders, completion: self.handleLoadResult)
        }
        if let parent = parent {
            print("Fetching serviceTypes of: \(parent.name!) \(parent.identifer.id)")
            
        }
    }
    
    private func handleLoadResult<Endpt: Endpoint>(_ result: Result<(HTTPURLResponse, Endpt, Endpt.ResponseBody), NetworkError>) where Endpt.ResponseBody == ResourceCollectionDocument<Models.Folder> {
        DispatchQueue.main.async {
            
            switch result {
            case let .success(_, _, document):
                print("Received folder contents: \(document.data!.map{$0.name})")
                self.folders = document.data ?? []
            case let .failure(error):
                print("Received Failed: \(error)")
                self.folders = []
            }
        }
    }
    
    private func handleServiceTypesLoadResult<Endpt: Endpoint>(_ result: Result<(HTTPURLResponse, Endpt, Endpt.ResponseBody), NetworkError>) where Endpt.ResponseBody == ResourceCollectionDocument<Models.ServiceType> {
        DispatchQueue.main.async {
            
            switch result {
            case let .success(_, _, document):
                print("Received service types: \(document.data!.map{$0.name})")
                self.serviceTypeNames = document.data!.map { .init($0.name!, id: $0.identifer.id) }
            case let .failure(error):
                print("Received Failed: \(error)")
                self.serviceTypeNames = []
            }
        }
    }
    
    var objectWillChange = PassthroughSubject<Void, Never>()
}
