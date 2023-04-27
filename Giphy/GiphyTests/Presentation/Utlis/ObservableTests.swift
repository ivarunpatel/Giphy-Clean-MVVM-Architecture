//
//  ObservableTests.swift
//  GiphyTests
//
//  Created by Varun on 27/04/23.
//

import XCTest
import Giphy

final class ObservableTests: XCTestCase {
    
    func test_subscribe_returnsValueToListner() {
        
        let expectedValue = "SomeValue"
        let observable = Observable(expectedValue)
        
        let expectation = expectation(description: "Waiting for listner")
        
        var receivedValue: String?
        observable.subscribe { value in
            receivedValue = value
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedValue, expectedValue)
    }
    
    func test_subscribe_returnsUpdatedValueOnSettingNewValue() {
        
        let observable = Observable("SomeValue")
        
        let expectation = expectation(description: "Waiting for listner")
        expectation.expectedFulfillmentCount = 2
        
        var receivedValue: String?
        observable.subscribe { value in
            receivedValue = value
            expectation.fulfill()
        }
        
        let expectedValue = "SomeNewValue"
        observable.value = expectedValue
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedValue, expectedValue)
    }
    
    func test_unsubscribe_doesNotReturnNewValuesAfterUnsubscription() {
        
        let expectedValue = "SomeValue"
        let observable = Observable(expectedValue)
        
        let expectation = expectation(description: "Waiting for listner")
        
        var receivedValue: String?
        observable.subscribe { value in
            receivedValue = value
            expectation.fulfill()
        }
        
        observable.unsubscribe()
        
        observable.value = "SomeNewValue"
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedValue, expectedValue)
    }
}
