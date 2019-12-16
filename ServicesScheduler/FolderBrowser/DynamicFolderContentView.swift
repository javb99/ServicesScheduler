//
//  DynamicFolderContentView.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

protocol FolderContentProvider: ObservableObject {
    var folderNames: [PresentableFolder] { get }
    var serviceTypeNames: [PresentableServiceType] { get }
    func load()
}

struct DynamicFolderContentView<DestinationFactory: FolderDestinationFactory, Provider: FolderContentProvider> : View {
    let folderName: String
    let destinationFactory: DestinationFactory
    @ObservedObject var provider: Provider
    
    var body: some View {
        FolderContentView(destinationFactory: destinationFactory,
                          folderName: folderName,
                          folderNames: provider.folderNames,
                          serviceTypeNames: provider.serviceTypeNames)
            .onAppear { self.provider.load() }
    }
}
