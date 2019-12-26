//
//  MyTeamsScreen.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 11/8/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct ServiceTypeTeams {
    var serviceType: PresentableServiceType
    var teams: [PresentableTeam]
}

protocol MyTeamsScreenModel: ObservableObject {
    var myTeams: [ServiceTypeTeams] { get }
    var isLoadingMyTeams: Bool { get }
    var selectedTeams: Set<Team.ID> { get set }
}

struct MyTeamsScreen<Model: MyTeamsScreenModel>: View {
    @ObservedObject var model: Model
    var chooseTeams: ()->()
    
    var body: some View {
        VStack {
            List() {
                if model.isLoadingMyTeams && model.myTeams.isEmpty {
                    Text("Loading teams you belong to...")
                } else if model.myTeams.isEmpty {
                    Text("You don't belong to any teams.")
                } else {
                    teamsSection(model.myTeams)
                }
                Section() {
                    PrimaryActionRow(
                        iconName: "plus.circle",
                        title: model.myTeams.isEmpty ? "Choose teams" : "Choose more",
                        action: chooseTeams
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
    
    func teamsSection(_ teamsByServiceType: [ServiceTypeTeams]) -> some View {
        ForEach(teamsByServiceType, id: \.serviceType.id) { (serviceType: ServiceTypeTeams) in
            Section(header: Text(serviceType.serviceType.value)) {
                ForEach(serviceType.teams, id: \.id) { (team: PresentableTeam) in
                    Toggle(isOn: does(self.selectedTeams, contain: team.id)) {
                        Text(team.name)
                    }.toggleStyle(CheckmarkStyle())
                }
            }
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
            }
            Spacer()
        }
    }
}

struct MyTeamsScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LightAndDark {
                MyTeamsScreen(
                    model: MyTeamsScreenStaticModel(
                        myTeams: [ServiceTypeTeams(serviceType: PresentableServiceType("Sanctuary", id: "123"), teams: [PresentableTeam(id: "2", name: "Technical Team", sequenceIndex: 0)]*5)],
                        isLoadingMyTeams: false,
                        selectedTeams: ["1"]),
                    chooseTeams: {}
                )
            }
            MyTeamsScreen(
                model: MyTeamsScreenStaticModel(
                    myTeams: [],
                    isLoadingMyTeams: true,
                    selectedTeams: ["2"]),
                chooseTeams: {}
            )
            MyTeamsScreen(
                model: MyTeamsScreenStaticModel(
                    myTeams: [],
                    isLoadingMyTeams: false,
                    selectedTeams: ["1"]),
                chooseTeams: {}
            )
        }
    }
}

class MyTeamsScreenStaticModel: MyTeamsScreenModel {

    init(myTeams: [ServiceTypeTeams] = [], isLoadingMyTeams: Bool = false, selectedTeams: Set<Team.ID> = []) {
        self.myTeams = myTeams
        self.isLoadingMyTeams = isLoadingMyTeams
        self.selectedTeams = selectedTeams
    }

    var myTeams: [ServiceTypeTeams] = [] {
           willSet {
               objectWillChange.send()
           }
       }
    var isLoadingMyTeams: Bool = false {
           willSet {
               objectWillChange.send()
           }
       }
    var selectedTeams: Set<Team.ID> = [] {
        willSet {
            objectWillChange.send()
        }
    }

    var objectWillChange = ObjectWillChangePublisher()
}

func identity<T>(_ t: T) -> T {
    return t
}

func *<T>(_ array: [T], _ repeatCount: Int) -> [T] {
    Array<[T]>(repeating: array, count: repeatCount).flatMap(identity)
}
