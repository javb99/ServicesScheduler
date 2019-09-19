//
//  ServiceTypeTeamSelectionView.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/19/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct Team: Identifiable {
    typealias ID = String
    var id: ID
    var name: String
}

struct ServiceTypeTeamSelectionView: View {
    
    @Binding var selection: Set<Team.ID>
    var teams: [Team]
    var serviceTypeName: String
    
    var body: some View {
        List(teams, selection: $selection) { team in
            Text(team.name)
        }
        .environment(\.editMode, .constant(EditMode.active))
        .navigationBarTitle(serviceTypeName)
    }
}

#if DEBUG
struct ServiceTypeTeamSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ServiceTypeTeamSelectionView(selection: Binding(get: {Set<String>()}, set: {_ in}), teams: [.init(id: "1", name:"Band")], serviceTypeName: "STUDENTS Wednesdays")
        }
    }
}
#endif
