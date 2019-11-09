//
//  MyTeamsScreen.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 11/8/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

protocol MyTeamsScreenModel: ObservableObject {
    var myTeams: [Team] { get }
    var isLoadingMyTeams: Bool { get }
    var otherTeams: [Team] { get }
    var selectedTeams: Set<Team.ID> { get set }
    var chooseTeams: ()->() { get }
}

struct MyTeamsScreen<Model: MyTeamsScreenModel>: View {
    @ObservedObject var model: Model
    
    var body: some View {
        VStack {
            List() {
                Section(header: Text("My Teams")) {
                    if model.isLoadingMyTeams && model.myTeams.isEmpty {
                        Text("Loading teams you lead...")
                    } else if model.myTeams.isEmpty {
                        Text("You don't lead any teams.")
                    } else {
                        teamsSection(teams: model.myTeams)
                    }
                }
                Section(header: Text("Other Teams")) {
                    teamsSection(teams: model.otherTeams)
                    PrimaryActionRow(
                        iconName: "plus.circle",
                        title: model.otherTeams.isEmpty ? "Choose teams" : "Choose more",
                        action: model.chooseTeams
                    )
                }
            }
            .listStyle(GroupedListStyle())
            .accentColor(.servicesGreen)
        }
    }
    
    var selectedTeams: Binding<Set<Team.ID>> {
        return self.$model.selectedTeams
    }
    
    func teamsSection(teams: [Team]) -> some View {
        ForEach(teams) { (team: Team) in
            Toggle(isOn: does(self.selectedTeams, contain: team.id)) {
                Text(team.value)
            }.toggleStyle(CheckmarkStyle())
        }
    }
}

struct PrimaryActionRow: View {
    let iconName: String
    let title: String
    let action: ()->()
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                HStack {
                    Image(systemName: iconName)
                    Text(title)
                }
            }.frame(alignment: .center)
            Spacer()
        }
    }
}

struct MyTeamsScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LightAndDark {
                MyTeamsScreen(model: MyTeamsScreenStaticModel(
                    myTeams: [Team("New Believers Team", id: "1")]*4,
                    isLoadingMyTeams: false,
                    otherTeams: [Team("Technical Team", id: "2")]*3,
                    selectedTeams: ["1"],
                    chooseTeams: {}
                ))
            }
            MyTeamsScreen(model: MyTeamsScreenStaticModel(
                myTeams: [],
                isLoadingMyTeams: true,
                otherTeams: [Team("Technical Team", id: "2")]*10,
                selectedTeams: ["2"],
                chooseTeams: {}
            ))
            MyTeamsScreen(model: MyTeamsScreenStaticModel(
                myTeams: [],
                isLoadingMyTeams: false,
                otherTeams: [],
                selectedTeams: ["1"],
                chooseTeams: {}
            ))
        }
    }
}

class MyTeamsScreenStaticModel: MyTeamsScreenModel {
    internal init(myTeams: [Team], isLoadingMyTeams: Bool, otherTeams: [Team], selectedTeams: Set<Team.ID>, chooseTeams: @escaping () -> ()) {
        self._myTeams = Published(initialValue: myTeams)
        self._isLoadingMyTeams = Published(initialValue: isLoadingMyTeams)
        self._otherTeams = Published(initialValue: otherTeams)
        self._selectedTeams = Published(initialValue: selectedTeams)
        self._chooseTeams = Published(initialValue: chooseTeams)
    }
    
    @Published var myTeams: [Team]
    @Published var isLoadingMyTeams: Bool
    @Published var otherTeams: [Team]
    @Published var selectedTeams: Set<Team.ID>
    @Published var chooseTeams: ()->()
}

func identity<T>(_ t: T) -> T {
    return t
}

func *<T>(_ array: [T], _ repeatCount: Int) -> [T] {
    Array<[T]>(repeating: array, count: repeatCount).flatMap(identity)
}
