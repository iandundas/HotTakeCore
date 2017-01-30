//
//  ContainerWithManualTests.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 05/06/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import XCTest
import ReactiveKit
import Nimble
import Bond

@testable import HotTakeCore

class ContainerWithManualTests: XCTestCase {

    let bag = DisposeBag()
    
    let emptyCollection = [Cat]()
    
    let nonemptyCollection = [
        Cat(name: "Mr A"),
        Cat(name: "Mr B"),
        Cat(name: "Mr C"),
    ]
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        bag.dispose()
        super.tearDown()
    }

    func testInitialEventWhenStartingWithEmptyCollection(){
        let container = ManualDataSource<Cat>(items: []).encloseInContainer()
        
        let firstChangeset = ChangesetProperty(nil)
        container.collection.element(at: 0).bind(to: firstChangeset)

        let secondChangeset = ChangesetProperty(nil)
        container.collection.element(at: 1).bind(to: secondChangeset)
        
        expect(firstChangeset.value?.change).toEventually(equal(ObservableArrayChange.reset))
        expect(secondChangeset.value).to(beNil())
    }
        
    func testInitialEventWhenStartingWithNonemptyCollection(){
        let container = ManualDataSource<Cat>(items: nonemptyCollection).encloseInContainer()
        
        var initialItems = [Cat]()
        var detectedInitialEvent = false
        container.collection.observeNext { changes in
            guard changes.resetted else {fail("Should be initial event"); return}
            let noMutations = changes.resetted
            detectedInitialEvent = noMutations
            
            initialItems = changes.source.array
        }.dispose(in: bag)
    
        expect(detectedInitialEvent).toEventually(beTrue())
        expect(initialItems).toEventually(equal(nonemptyCollection))
    }

    // Expecting a single corrected initial event, rather than any reported updates
    func testInitialEventWhenObservingAfterInsertingOnAnEmptyDataSource(){
        let datasource = ManualDataSource<Cat>(items: emptyCollection)
        let dsc = datasource.encloseInContainer()
        
        datasource.replaceItems(items: nonemptyCollection)
        
        var initialItems = [Cat]()
        var detectedInitialEvent = false
        dsc.collection.observeNext { changes in
            guard changes.resetted else {fail("Should be initial event"); return}
            detectedInitialEvent = changes.resetted
            
            initialItems = changes.source.array
        }.dispose(in: bag)
        
        expect(detectedInitialEvent).toEventually(beTrue())
        expect(initialItems).toEventually(equal(nonemptyCollection))
    }

    func testInitialSubscriptionSendsASingleCurrentStateEventWhenInitiallyObserved(){
        
        var observeCallCount = 0
        let container = ManualDataSource<Cat>(items: [Cat]()).encloseInContainer()
        
        container.collection
            .observeNext { changes in
                guard changes.resetted else {fail("Should be initial event"); return}
                
                observeCallCount += 1
            }.dispose(in: bag)
        
        expect(observeCallCount).toEventually(equal(1), timeout: 1)
        expect(observeCallCount).toEventuallyNot(beGreaterThan(1), timeout: 1)
    }
    
    func testSwapEmptyForEmptyProducesNoChange(){
        
        let container = ManualDataSource<Cat>(items: [Cat]()).encloseInContainer()

        let firstChangeset = ChangesetProperty(nil)
        container.collection.element(at: 0).bind(to: firstChangeset)
        
        let secondChangeset = ChangesetProperty(nil)
        container.collection.element(at: 1).bind(to: secondChangeset)

        // replace datasource:
        container.datasource = ManualDataSource<Cat>(items: [Cat]()).eraseType()

        expect(firstChangeset.value?.change).to(equal(ObservableArrayChange.reset))
        expect(secondChangeset.value).to(beNil())
    }
    
    func testSwapNonemptyForEmptyProducesNoChange(){
        
        let container = ManualDataSource<Cat>(items: nonemptyCollection).encloseInContainer()

        let firstChangeset = ChangesetProperty(nil)
        container.collection.element(at: 0).bind(to: firstChangeset)
        
        let thirdChangeset = ChangesetProperty(nil)
        container.collection.element(at: 2).bind(to: thirdChangeset)
        
        let fifthChangeset = ChangesetProperty(nil)
        container.collection.element(at: 4).bind(to: fifthChangeset)
        
        let seventhChangeset = ChangesetProperty(nil)
        container.collection.element(at: 6).bind(to: seventhChangeset)
        
        // replace datasource:
        container.datasource = ManualDataSource<Cat>(items: [Cat]()).eraseType()
        
        expect(firstChangeset.value?.change).to(equal(ObservableArrayChange.reset))
        expect(thirdChangeset.value?.change).to(equal(ObservableArrayChange.deletes([0])))
        expect(fifthChangeset.value?.change).to(equal(ObservableArrayChange.deletes([2])))
        expect(seventhChangeset.value).to(beNil())
    }
    
    func testMutationProducesChange(){
        let datasource = ManualDataSource<Cat>(items: nonemptyCollection)
        let container = datasource.encloseInContainer()
        let events = container.collection.store()
        
        // mutate datasource:
        datasource.replaceItems(items: emptyCollection)

        expect(events[0]?.change) == ObservableArrayChange.reset
        expect(events[1]?.change) == ObservableArrayChange.beginBatchEditing
        expect(events[2]?.change) == ObservableArrayChange.deletes([0])
        expect(events[3]?.change) == ObservableArrayChange.deletes([1])
        expect(events[4]?.change) == ObservableArrayChange.deletes([2])
        expect(events[5]?.change) == ObservableArrayChange.endBatchEditing
    }
}

