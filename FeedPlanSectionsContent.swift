//
//  FeedPlanSectionsContent.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/25/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct FeedPlanSectionsContent: View {
    
    var plans: [PresentableFeedPlan]
    
    var body: some View {
        ForEach(plans) { plan in
            self.planSection(for: plan)
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
struct FeedPlanSectionsContent_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(Bool.allCases, id: \.self) { canLoadPlans in
            LightAndDark {
                NavigationView {
                    List {
                        FeedPlanSectionsContent(plans: .sample)
                    }.navigationBarTitle("Feed")
                }
            }
        }
    }
}
#endif
