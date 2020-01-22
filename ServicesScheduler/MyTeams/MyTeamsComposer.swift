//
//  MyTeamsComposer.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/21/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import PlanningCenterSwift

class MyTeamsComposer {
    
    static func createPresenter(network: PCODownloadService) -> MyTeamsScreenPresenter {
        let meLoader = NetworkMeService(network: network)
        let teamLoader = NetworkTeamWithServiceTypeService(
            network: network
        ).load
        let myTeamsLoader = NetworkMyTeamsService(
            network: network,
            meService: meLoader,
            teamService: teamLoader
        )
        let teamPresenter = MyTeamsScreenPresenter(myTeamsService: myTeamsLoader)
        return teamPresenter
    }
}
