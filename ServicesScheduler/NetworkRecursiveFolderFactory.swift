//
//  NetworkRecursiveFolderFactory.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift
import SwiftUI

struct NetworkRecursiveFolderFactory: FolderDestinationFactory {
    let network: URLSessionService
    let provider: FolderLoader
    
    func destination(forFolder folder: String) -> some View {
        let newParent = provider.folders.first(where: {$0.name==folder})
        let newProvider = FolderLoader(network: network, parent: newParent)
        return DynamicFolderContentView(destinationFactory: Self(network: network, provider: newProvider), provider: newProvider)
    }
    
    func destination(forServiceType serviceType: String) -> some View {
        ServiceTypeTeamSelectionView(selection: Binding(get: {Set<String>()}, set: {_ in}), teams: [.init(id: "1", value: "Band"), .init(id: "2", value: "Tech")], serviceTypeName: serviceType)
    }
}
