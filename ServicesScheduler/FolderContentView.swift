//
//  FolderContentView.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 7/27/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

protocol FolderDestinationFactory {
    associatedtype FolderView: View
    func destination(forFolder folder: PresentableFolder) -> FolderView
    associatedtype ServiceTypeView: View
    func destination(forServiceType serviceType: PresentableServiceType) -> ServiceTypeView
}

typealias PresentableFolder = Identified<String, String>
typealias PresentableServiceType = Identified<String, String>

struct FolderContentView<DestinationFactory: FolderDestinationFactory> : View {
    
    let destinationFactory: DestinationFactory
    
    let folderName: String
    var folderNames: [PresentableFolder]
    var serviceTypeNames: [PresentableServiceType]
    
    var body: some View {
        List() {
            ForEach(folderNames) { folder in
                self.folderRow(for: folder)
            }
            
            Section(header: Text("SERVICE TYPES")) {
                ForEach(serviceTypeNames) { serviceType in
                    self.serviceTypeRow(for: serviceType)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(folderName)
    }
    
    fileprivate func folderRow(for folder: PresentableFolder) -> some View {
        NavigationLink(destination: destinationFactory.destination(forFolder: folder)) {
            HStack(spacing: 15) {
                Image(systemName: "folder")
                    .foregroundColor(Color.green)
                Text(folder.value)
            }
        }
    }
    
    fileprivate func serviceTypeRow(for serviceType: PresentableServiceType) -> some View {
        NavigationLink(destination: destinationFactory.destination(forServiceType: serviceType)) {
            Text(serviceType.value)
        }
    }
}

#if DEBUG
struct FolderContentView_Previews : PreviewProvider {
    static var previews: some View {
        NavigationView {
            FolderContentView(destinationFactory: RecursiveFolderFactory(),
                              folderName: "Crossroads",
                              folderNames: [.init("STUDENTS", id: "1"), .init("YA", id: "2")],
                              serviceTypeNames: [.init("Sunday Mornings", id: "1")])
        }
    }
}
#endif
