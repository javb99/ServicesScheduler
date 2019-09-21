//
//  RecursiveFolderFactory.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI
import PlanningCenterSwift

struct RecursiveFolderFactory: FolderDestinationFactory {
    
    func destination(forFolder folder: String) -> some View {
        FolderContentView(destinationFactory: Self(), folderName: folder, folderNames: ["Sanctuary", "STUDENTS", "YA"], serviceTypeNames: ["Online"])
    }
    
    func destination(forServiceType serviceType: String) -> some View {
        ServiceTypeTeamSelectionView(selection: Binding(get: {Set<String>()}, set: {_ in}), teams: [.init(id: "1", name: "Band"), .init(id: "2", name: "Tech")], serviceTypeName: serviceType)
    }
}
