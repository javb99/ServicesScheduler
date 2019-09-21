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
    var selection: Binding<Set<Team.ID>>?
    
    func destination(forFolder folder: PresentableFolder) -> some View {
        let newParent = provider.folder(for: folder)
        let newProvider = FolderLoader(network: network, parent: newParent)
        
        return DynamicFolderContentView(
            destinationFactory: Self(
                network: network,
                provider: newProvider,
                selection: selection
            ),
            provider: newProvider
        )
    }
    
    func destination(forServiceType serviceType: PresentableServiceType) -> some View {
        ServiceTypeTeamSelectionView(
            selection: selection,
            teams: [.init("Band", id: "1"), .init("Tech", id: "2")],
            serviceTypeName: serviceType.value
        )
    }
}
