//
//  Snapshotting+AppStore.swift
//  ServicesSchedulerTests
//
//  Created by Joseph Van Boxtel on 12/19/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import XCTest
import SnapshotTesting
import SwiftUI

extension XCTestCase {
    func assertAppStoreSnapshots<V: View>(matching view: V, file: StaticString = #file, function: String = #function, line: UInt = #line) {
        assertSnapshot(matching: view, as: .image(on: .iPhoneSe), file: file, testName: function + "iPhoneSe", line: line)
        assertSnapshot(matching: view, as: .image(on: .iPhoneX), file: file, testName: function + "iPhoneX", line: line)
        assertSnapshot(matching: view, as: .image(on: .iPhoneXsMax), file: file, testName: function + "iPhoneXsMax", line: line)
    }
}
