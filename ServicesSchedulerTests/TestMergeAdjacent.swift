//
//  TestMergeAdjacent.swift
//  ServicesSchedulerTests
//
//  Created by Joseph Van Boxtel on 10/5/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import XCTest
import Scheduler

class TestMergeAdjacent: XCTestCase {

    func test_empty_IsEmpty() {
        let items = [Item]()
        let result = computeResultUsingSUT(items)
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_single_resultIsUnchanged() {
        let items = [Item(id: 1, name: "Joe")]
        
        let result = computeResultUsingSUT(items)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first!.id, 1)
        XCTAssertEqual(result.first!.name, "Joe")
    }
    
    func test_multipleNotMatching_resultIsUnchanged() {
        let items = [Item(id: 1, name: "Joe"), Item(id: 2, name: "Sam")]
        
        let result = computeResultUsingSUT(items)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first!.id, 1)
        XCTAssertEqual(result.first!.name, "Joe")
        XCTAssertEqual(result.last!.id, 2)
        XCTAssertEqual(result.last!.name, "Sam")
    }
    
    func test_multipleMatching_areMerged() {
        let items = [Item(id: 1, name: "Joe"), Item(id: 1, name: "Sam")]
        
        let result = computeResultUsingSUT(items)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first!.id, 1)
        XCTAssertEqual(result.first!.name, "Joe, Sam")
    }
    
    func test_multipleMatchingButSeparated_areNotMerged() {
        let items = [Item(id: 1, name: "Joe"), Item(id: 2, name: "Abbie"), Item(id: 1, name: "Sam")]
        let result = computeResultUsingSUT(items)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.first!.id, 1)
        XCTAssertEqual(result.first!.name, "Joe")
        XCTAssertEqual(result.last!.id, 1)
        XCTAssertEqual(result.last!.name, "Sam")
    }
    
    // MARK: Helpers
    
    func computeResultUsingSUT(_ items: [Item]) -> [Item] {
        items.mergeAdjacent(ifElementsShare: \.id, merge: Item.joinNamesWithComma(_:_:))
    }

    struct Item {
        var id: Int
        var name: String
        
        static func joinNamesWithComma(_ item1: Item, _ item2: Item) -> Item {
            var sum = item1
            sum.name = item1.name + ", " + item2.name
            return sum
        }
    }
}
