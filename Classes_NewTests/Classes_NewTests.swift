//
//  Classes_NewTests.swift
//  Classes_NewTests
//
//  Created by Gustavo Garfias on 28/06/21.
//

import XCTest
@testable import G_House__iOS_15____

class Classes_NewTests: XCTestCase {

    /*
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
     */

    func testItemWithoutVarieties() {
        let item = ItemNewS(empty: true)
        XCTAssertEqual(item.quantityAlertString, "")
    }

    /*
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
     */

}
