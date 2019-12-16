//
//  ServicesSchedulerUITests.swift
//  ServicesSchedulerUITests
//
//  Created by Joseph Van Boxtel on 7/27/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import XCTest

class ServicesSchedulerUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let app = XCUIApplication()
        let tabBarsQuery = app.tabBars
        tabBarsQuery.buttons["Teams"].tap()
        sleep(3)
        let tablesQuery = app.tables
        tablesQuery.children(matching: .cell).element(boundBy: 7).switches["Technical"].tap()
        tablesQuery.children(matching: .cell).element(boundBy: 10).switches["Band"].tap()
        tablesQuery.children(matching: .cell).element(boundBy: 13).switches["Technical"].tap()
        tablesQuery.children(matching: .cell).element(boundBy: 12).switches["Leadership Team"].tap()
        tablesQuery.children(matching: .cell).element(boundBy: 11).switches["Band"].tap()
        tabBarsQuery.buttons["Feed"].tap()
    }
}
