//
//  AttentionNeededFeedList.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 10/4/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

protocol FeedController: ObservableObject {
    var plans: [PresentableFeedPlan] { get }
    var isLoading: Bool { get }
    var canLoadMorePlans: Bool { get }
    func loadMorePlans()
    func reset(for teams: Set<MTeam.ID>)
}

extension FeedController {
    func reset(for teams: Set<String>) {
        self.reset(for: teams.map { raw in MTeam.ID(stringLiteral: raw) }.asSet())
    }
}

struct FeedListContainer<Controller>: View where Controller: FeedController {
    @ObservedObject var controller: Controller
    var feedBreakdownProvider: FeedBreakdownProvider
    var selectedTeams: Set<String>
    
    var body: some View {
        AttentionNeededFeedList(
            plans: controller.plans,
            canLoadMorePlans: controller.canLoadMorePlans,
            loadMorePlans: controller.loadMorePlans,
            breakdown: feedBreakdownProvider.getBreakdown(plans: controller.plans)
        )
        .onAppear { self.controller.reset(for: self.selectedTeams) }
    }
}

struct AttentionNeededFeedList: View {
    var plans: [PresentableFeedPlan]
    var canLoadMorePlans: Bool
    var loadMorePlans: ()->()
    var breakdown: FeedBreakdown?
    
    var body: some View {
        VStack {
            FeedHeader(breakdown: breakdown)
            List{
                FeedPlanSectionsContent(plans: plans)
                
                // TODO: Maybe use a delegate that listens to plans appearing and disapearing to trigger fetches and load more data.
                
                FeedReloadControls(canLoadMorePlans: false, loadMorePlans: loadMorePlans)
            }
        }
        
    }
}

#if DEBUG
struct AttentionNeededFeedList_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(Bool.allCases, id: \.self) { canLoadPlans in
            LightAndDark {
                AttentionNeededFeedList(plans: .sample, canLoadMorePlans: canLoadPlans, loadMorePlans: {}, breakdown: .sample)
            }
        }
    }
}

extension Bool: CaseIterable {
    public static var allCases = [true, false]
}

extension FeedBreakdown {
    static var sample: Self {
        Self(confirmed: 2, unconfirmed: 20, declined: 2, needed: 9, unsent: 100000)
    }
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
