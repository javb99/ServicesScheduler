//
//  AttentionNeededFeedList.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/4/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct Plan: Identifiable {
    var id: String
    var date: String
    var serviceTypeName: String
}

protocol FeedController: ObservableObject {
    var plans: [PresentableFeedPlan] { get }
    var canLoadMorePlans: Bool { get }
    func loadMorePlans()
    func reset(for teams: Set<MTeam.ID>)
}

class AdapterFeedController<DataSource>: FeedController where DataSource: AttentionNeededFeedDataSource {
    
    var dataSource: DataSource
    
    init(_ dataSource: DataSource) {
        self.dataSource = dataSource
    }
    
    var plans: [PresentableFeedPlan] {
        dataSource.plans.map { plan in
            PresentableFeedPlan(id: PresentableFeedPlan.ID(stringLiteral: plan.id), sortDate: Date(), date: plan.date, serviceTypeName: plan.serviceTypeName, teams: dataSource.teams(plan: plan))
        }
    }
    
    let canLoadMorePlans: Bool = false
    
    func loadMorePlans() {
        // Can't.
    }
    
    func reset(for teams: Set<MTeam.ID>) {}
    
    var objectWillChange: DataSource.ObjectWillChangePublisher { dataSource.objectWillChange }
}
extension FeedController {
    func reset(for teams: Set<Team.ID>) {
        self.reset(for: teams.map { raw in MTeam.ID(stringLiteral: raw) }.asSet())
    }
}

protocol AttentionNeededFeedDataSource: ObservableObject {
    
    var plans: [Plan] { get }
    func teams(plan: Plan) -> [PresentableFeedTeam]
}

struct FeedListContainer<Controller>: View where Controller: FeedController {
    @ObservedObject var controller: Controller
    var selectedTeams: Set<Team.ID>
    
    var body: some View {
        AttentionNeededFeedList(
            plans: controller.plans,
            canLoadMorePlans: controller.canLoadMorePlans,
            loadMorePlans: controller.loadMorePlans
        ).onAppear { self.controller.reset(for: self.selectedTeams) }
    }
}

struct AttentionNeededFeedList: View {
    var plans: [PresentableFeedPlan]
    var canLoadMorePlans: Bool
    var loadMorePlans: ()->()
    
    var body: some View {
        List{
            ForEach(plans) { plan in
                self.planSection(for: plan)
            }
            if canLoadMorePlans {
                Button(action: loadMorePlans) {
                    Text("Load more")
                }
            }
        }
    }
    
    func planHeader(for plan: PresentableFeedPlan) -> some View {
        VStack(alignment: .leading) {
            Text(plan.date).font(.headline)
            Text(plan.serviceTypeName).font(.body)
        }.padding(.vertical)
    }
    
    func planSection(for plan: PresentableFeedPlan) -> some View {
        Section(header: planHeader(for: plan)) {
            ForEach(plan.teams) { team in
                self.teamSection(for: team)
            }
        }
    }
    
    func teamSection(for team: PresentableFeedTeam) -> some View {
        Group {
            Text(team.name).font(.headline)
            ForEach(team.neededPostions, content: neededPositionRow)
            ForEach(team.teamMembers, content: teamMemberRow)
        }
    }
    
    func neededPositionRow(for neededPosition: PresentableNeededPosition) -> some View {
        HStack(spacing: 8) {
            NeededPositionCircle(count: neededPosition.count)
                .frame(width: 44, height: 44, alignment: .leading)
            Text(neededPosition.title)
        }
    }
    
    func teamMemberRow(for teamMember: PresentableTeamMember) -> some View {
        HStack(spacing: 8) {
            StatusCircle(status: teamMember.status)
                .frame(width: 44, height: 44, alignment: .leading)
            VStack(alignment: .leading) {
                Text(teamMember.name).font(.headline)
                Text(teamMember.position)
                    .lineLimit(2)
            }
            Spacer()
            if teamMember.hasUnsentNotification {
                NotificationNotSentView()
                .fixedSize()
                .font(.headline)
            }
        }
    }
}

#if DEBUG
struct AttentionNeededFeedList_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(Bool.allCases, id: \.self) { canLoadPlans in
            LightAndDark {
                NavigationView {
                    AttentionNeededFeedList(plans: .sample, canLoadMorePlans: canLoadPlans, loadMorePlans: {})
                    .navigationBarTitle("Title")
                }
            }
        }
    }
}

extension Bool: CaseIterable {
    public static var allCases = [true, false]
}

extension Array where Element == PresentableFeedPlan {
    
    static let sample = [
        PresentableFeedPlan(
            id: "1",
            sortDate: Date(),
            date: "Sunday Aug. 12",
            serviceTypeName: "Vancouver - Services - Weekend",
            teams: [
                PresentableFeedTeam(
                    id: "1",
                    name: "Band",
                    neededPostions: [
                        PresentableNeededPosition(
                            id: "1",
                            title: "Drums",
                            count: 1
                        )
                    ],
                    teamMembers: [
                        PresentableTeamMember(
                            id: "1",
                            name: "Joseph Van Boxtel",
                            position: "Music Director",
                            status: .confirmed,
                            hasUnsentNotification: false
                        )
                    ]
                ),
                PresentableFeedTeam(
                    id: "2",
                    name: "Tech",
                    neededPostions: [
                        PresentableNeededPosition(
                            id: "1",
                            title: "Front Of House",
                            count: 1
                        )
                    ],
                    teamMembers: [
                        PresentableTeamMember(
                            id: "2",
                            name: "Remington Smith",
                            position: "Head Hancho",
                            status: .confirmed,
                            hasUnsentNotification: true
                        )
                    ]
                )
            ]
    )]
}
#endif
