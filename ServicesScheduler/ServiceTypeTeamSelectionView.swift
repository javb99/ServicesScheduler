//
//  ServiceTypeTeamSelectionView.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/19/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

typealias Team = Identified<String, String>

struct ServiceTypeTeamSelectionView: View {
    
    var selection: Binding<Set<Team.ID>>?
    var teams: [Team]
    var serviceTypeName: String
    
    var body: some View {
        List(teams, selection: selection) { team in
            Text(team.value)
        }
        .environment(\.editMode, .constant(.active))
        .navigationBarTitle(serviceTypeName)
    }
}

#if DEBUG
struct ServiceTypeTeamSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        return NavigationView {
            ServiceTypeTeamSelectionView(
                selection: .constant(["1"]),
                teams: [.init("Band", id: "1"), .init("Tech", id: "2")],
                serviceTypeName: "STUDENTS Wednesdays"
            )
        }
    }
}
#endif
