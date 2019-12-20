//
//  TeamSelectionViewTests.swift
//  ServicesSchedulerTests
//
//  Created by Joseph Van Boxtel on 12/19/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Scheduler

class TeamSelectionViewTests: XCTestCase {

    func testSimpleList() {
        let view = NavigationView {
            TeamSelectionView(
                selection: .constant(["1"]),
                teams: [.init("Band", id: "1"), .init("Tech", id: "2")],
                title: "Sunday Worship"
            )
        }
        
        //record = true
        assertAppStoreSnapshots(matching: view)
    }
}
