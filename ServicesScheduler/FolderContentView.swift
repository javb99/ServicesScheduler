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
    func destination(forFolder folder: String) -> FolderView
    associatedtype ServiceTypeView: View
    func destination(forServiceType serviceType: String) -> ServiceTypeView
}

struct FolderContentView<DestinationFactory: FolderDestinationFactory> : View {
    typealias Folder = String
    typealias ServiceType = String
    
    let destinationFactory: DestinationFactory
    
    let folderName: String
    var folderNames: [String]
    var serviceTypeNames: [String]
    
    var body: some View {
        List() {
            ForEach(folderNames, id: \.self) { folder in
                self.folderRow(for: folder)
            }
            
            Section(header: Text("SERVICE TYPES")) {
                ForEach(serviceTypeNames, id: \.self) { serviceType in
                    self.serviceTypeRow(for: serviceType)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(folderName)
    }
    
    fileprivate func folderRow(for folder: Folder) -> some View {
        NavigationLink(destination: destinationFactory.destination(forFolder: folder)) {
            HStack(spacing: 15) {
                Image(systemName: "folder")
                    .foregroundColor(Color.green)
                Text(folder)
            }
        }
    }
    
    fileprivate func serviceTypeRow(for serviceType: ServiceType) -> some View {
        NavigationLink(destination: destinationFactory.destination(forServiceType: serviceType)) {
            Text(serviceType)
        }
    }
}

#if DEBUG
struct FolderContentView_Previews : PreviewProvider {
    static var previews: some View {
        NavigationView {
            FolderContentView(destinationFactory: RecursiveFolderFactory(),
                              folderName: "Crossroads",
                              folderNames: ["STUDENTS", "YA"],
                              serviceTypeNames: ["Sunday Morning"])
        }
    }
}
#endif
