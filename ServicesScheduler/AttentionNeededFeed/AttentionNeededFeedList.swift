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

struct NeededPosition: Identifiable {
    var id: String
    var title: String
    var count: Int
}

struct TeamMember: Identifiable {
    var id: String
    var name: String
    var position: String
    var status: PresentableStatus
    var hasUnsentNotification: Bool
}

protocol AttentionNeededFeedDataSource: ObservableObject {
    
    var plans: [Plan] { get }
    func teams(plan: Plan) -> [Team]
    func neededPositions(plan: Plan, team: Team) -> [NeededPosition]
    func teamMembers(plan: Plan, team: Team) -> [TeamMember]
}

struct AttentionNeededFeedList<DataSource>: View where DataSource: AttentionNeededFeedDataSource {
    @ObservedObject var dataSource: DataSource
    
    var body: some View {
        List{
            ForEach(dataSource.plans) { plan in
                self.planSection(for: plan)
            }
        }
    }
    
    func planHeader(for plan: Plan) -> some View {
        VStack(alignment: .leading) {
            Text(plan.date).font(.headline)
            Text(plan.serviceTypeName).font(.body)
        }.padding(.vertical)
    }
    
    func planSection(for plan: Plan) -> some View {
        Section(header: planHeader(for: plan)) {
            ForEach(dataSource.teams(plan: plan)) { team in
                self.teamSection(for: team, in: plan)
            }
        }
    }
    
    func teamSection(for team: Team, in plan: Plan) -> some View {
        Group {
            Text(team.value).font(.headline)
            ForEach(dataSource.neededPositions(plan: plan, team: team), content: neededPositionRow)
            ForEach(dataSource.teamMembers(plan: plan, team: team), content: teamMemberRow)
        }
    }
    
    func neededPositionRow(for neededPosition: NeededPosition) -> some View {
        HStack(spacing: 8) {
            NeededPositionCircle(count: neededPosition.count)
                .frame(width: 44, height: 44, alignment: .leading)
            Text(neededPosition.title)
        }
    }
    
    func teamMemberRow(for teamMember: TeamMember) -> some View {
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
        LightAndDark {
            NavigationView {
                AttentionNeededFeedList(dataSource: ConstAttentionNeededFeedListData.sample)
                .navigationBarTitle("Title")
            }
        }
    }
}
#endif
