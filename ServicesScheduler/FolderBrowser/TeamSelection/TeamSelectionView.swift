//
//  ServiceTypeTeamSelectionView.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 9/19/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

typealias Team = Identified<String, String>

protocol TeamProvider: ObservableObject {
    var teams: [Team] { get }
    func load()
}

struct TeamSelectionContainer<Provider: TeamProvider>: View {
    var selection: Binding<Set<Team.ID>>
    @ObservedObject var provider: Provider
    var title: String
    
    var body: some View {
        TeamSelectionView(
            selection: selection,
            teams: provider.teams,
            title: title
        ).onAppear { self.provider.load() }
    }
}

struct TeamSelectionView: View {
    
    var selection: Binding<Set<Team.ID>>
    var teams: [Team]
    var title: String
    
    var body: some View {
        SelectableList(teams, selection: self.selection) { team in
            Text(team.value)
        }
        .navigationBarTitle(title)
    }
}

#if DEBUG
struct TeamSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        AllSizes {
            LightAndDark {
                NavigationView {
                    TeamSelectionView(
                        selection: .constant(["1"]),
                        teams: [.init("Band", id: "1"), .init("Tech", id: "2")],
                        title: "STUDENTS Wednesdays"
                    )
                }
            }
        }
    }
}
#endif
