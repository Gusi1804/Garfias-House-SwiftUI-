//
//  G_House_Tests.swift
//  G House Tests
//
//  Created by Gustavo Garfias on 28/06/21.
//

import XCTest
@testable import G_House__iOS_15____

class G_House_Tests: XCTestCase {
    
    func testItemWithoutVarieties() {
        let item = ItemNewS(empty: true)
        XCTAssertEqual(item.quantityAlertString, "")
    }

}
