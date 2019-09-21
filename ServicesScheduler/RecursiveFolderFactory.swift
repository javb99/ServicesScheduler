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
    
    func destination(forFolder folder: PresentableFolder) -> some View {
        FolderContentView(
            destinationFactory: Self(),
            folderName: folder.value,
            folderNames: [.init("STUDENTS", id: "1"), .init("YA", id: "2"), .init("Sanctuary", id: "3")],
            serviceTypeNames: [.init("Online", id:"1")]
        )
    }
    
    func destination(forServiceType serviceType: PresentableServiceType) -> some View {
        ServiceTypeTeamSelectionView(
            selection: .constant(["1"]),
            teams: [.init("Band", id: "1"), .init("Tech", id: "2")],
            serviceTypeName: serviceType.value
        )
    }
}
