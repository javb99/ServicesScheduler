//
//  DynamicFolderContentView.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/21/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

protocol FolderContentProvider: ObservableObject {
    var folderName: String { get }
    var folderNames: [PresentableFolder] { get }
    var serviceTypeNames: [PresentableServiceType] { get }
    func load()
}

struct DynamicFolderContentView<DestinationFactory: FolderDestinationFactory, Provider: FolderContentProvider> : View {
    let destinationFactory: DestinationFactory
    @ObservedObject var provider: Provider
    
    var body: some View {
        FolderContentView(destinationFactory: destinationFactory,
                          folderName: provider.folderName,
                          folderNames: provider.folderNames,
                          serviceTypeNames: provider.serviceTypeNames)
            .onAppear { self.provider.load() }
    }
}
