//
//  ManualDatasource.swift
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

/* 
 Rules: 
  - Observers should receive the current contents of the internal container in an "initial" notification.
  - Observers should receive correct diff notifications when things change
 */

class ManualDatasourceTests: XCTestCase {

    let catA = Cat(name: "Mr A")
    let catB = Cat(name: "Mr B")
    let catC = Cat(name: "Mr C")

    var emptyArray: [Cat]!
    var nonEmptyArray: [Cat]!
    
    let bag = DisposeBag()
    
    var datasource: ManualDataSource<Cat>!
    
    override func setUp() {
        super.setUp()
        emptyArray = []
        nonEmptyArray = [catA]
    }
    
    override func tearDown() {
        datasource = nil
        bag.dispose()
        super.tearDown()
    }
    
    func testInitialNotificationIsReceived(){
        datasource = ManualDataSource<Cat>(items: [catA, catB])
        
        let firstEvent = ChangesetProperty(nil)
        let secondEvent = ChangesetProperty(nil)
        
        datasource.mutations().element(at: 0).bind(to: firstEvent).dispose(in: bag)
        datasource.mutations().element(at: 1).bind(to: secondEvent).dispose(in: bag)
        
        expect(firstEvent.value?.change).to(equal(ObservableArrayChange.reset))
        expect(secondEvent.value?.change).to(beNil())
    }
    
    func testInsertEventIsReceived(){
        datasource = ManualDataSource<Cat>(items: [])
        let events = datasource.mutations().store()
        
        datasource.replaceItems(items: [catA, catB])
        
        expect(events[1]?.change) == ObservableArrayChange.beginBatchEditing
        expect(events[2]?.change) == ObservableArrayChange.inserts([0])
        expect(events[3]?.change) == ObservableArrayChange.inserts([1])
        expect(events[4]?.change) == ObservableArrayChange.endBatchEditing
        
        expect(events.count) == 5
    }
    
    func testDeleteEventIsReceived(){
        let items = [catA, catB]
        datasource = ManualDataSource<Cat>(items: items)
        
        let events = datasource.mutations().store()
       
        datasource.replaceItems(items: [])
        
        expect(events[1]?.change) == ObservableArrayChange.beginBatchEditing
        expect(events[2]?.change) == ObservableArrayChange.deletes([0])
        expect(events[3]?.change) == ObservableArrayChange.deletes([1])
        expect(events[4]?.change) == ObservableArrayChange.endBatchEditing
    }
    

    func testBasicInsertBindingWhereObserverIsBoundBeforeInsert() {
        datasource = ManualDataSource<Cat>(items: [])
        let events = datasource.mutations().store()

        datasource.replaceItems(items: [catA])
        
        expect(events[0]?.dataSource).to(beEmpty())
        expect(events[2]?.change) == ObservableArrayChange.inserts([0])
        expect(events[3]?.change) == ObservableArrayChange.endBatchEditing
    }

    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithoutDelay() {
        datasource = ManualDataSource<Cat>(items: [])
        
        datasource.replaceItems(items: [catA])
        
        let events = datasource.mutations().store()
        
        expect(events[0]?.source).to(haveCount(1))
        expect(events[1]?.source).to(beNil())
    }
    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithADelay() {
        datasource = ManualDataSource<Cat>(items: [])
        
        datasource.replaceItems(items: [catA])
        
        let firstChangeset = ChangesetProperty(nil)
        let secondChangeset = ChangesetProperty(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.datasource.mutations().element(at: 0).bind(to: firstChangeset)
            self.datasource.mutations().element(at: 1).bind(to: secondChangeset)
        }
        
        expect(firstChangeset.value?.source).toEventually(haveCount(1))
        expect(firstChangeset.value?.change).toEventually(equal(ObservableArrayChange.reset))
        expect(secondChangeset.value).toEventually(beNil())
        expect(secondChangeset.value).toEventually(beNil())
        
    }
    
    
    func testBasicInsertBindingWhereObserverIsBoundBeforeInsertAndAnItemIsAlreadyAdded() {
        datasource = ManualDataSource<Cat>(items: [catA])
        let events = datasource.mutations().store()

        datasource.replaceItems(items: [catA, catB])

        expect(events[0]?.source).to(haveCount(1))
        
        expect(events[2]?.source).to(haveCount(2))
        expect(events[2]?.change) == ObservableArrayChange.inserts([1])
    }
    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithoutDelayAndAnItemIsAlreadyAdded() {
        datasource = ManualDataSource<Cat>(items: [catA])
        
        datasource.replaceItems(items:[catA, catB])
        
        let events = datasource.mutations().store()
        
        expect(events[0]?.source).to(haveCount(2))
        expect(events[0]?.change) == ObservableArrayChange.reset
        
        expect(events[1]).to(beNil())
    }

    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithADelayAndAnItemIsAlreadyAdded() {
        datasource = ManualDataSource<Cat>(items: [catA])
        
        datasource.replaceItems(items: [catA, catB])
        
        let firstChangeset = ChangesetProperty(nil)
        let secondChangeset = ChangesetProperty(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.datasource.mutations().element(at: 0).bind(to: firstChangeset)
            self.datasource.mutations().element(at: 1).bind(to: secondChangeset)
        }
        
        expect(firstChangeset.value?.source).toEventually(haveCount(2))
        expect(firstChangeset.value?.change).to(equal(ObservableArrayChange.reset))
        
        expect(secondChangeset.value).toEventually(beNil())
    }

    func testBasicDeleteWhereCollectionIsEmptyWhenObservingAfterwards() {
        datasource = ManualDataSource<Cat>(items: [catA])
        
        datasource.replaceItems(items:[])
        
        let firstChangeset = ChangesetProperty(nil)
        let secondChangeset = ChangesetProperty(nil)
        
        self.datasource.mutations().element(at: 0).bind(to: firstChangeset)
        self.datasource.mutations().element(at: 1).bind(to: secondChangeset)
        
        expect(firstChangeset.value?.source).to(haveCount(0))
        expect(firstChangeset.value?.change).to(equal(ObservableArrayChange.reset))
        
        expect(secondChangeset.value).to(beNil())
        expect(secondChangeset.value).to(beNil())
    }
    
    func testBasicDeleteWhereCollectionEmptiesAfterObservingBeforehand() {
        datasource = ManualDataSource<Cat>(items: [catA])
        
        let events = datasource.mutations().store()
        
        datasource.replaceItems(items: [])
        
        expect(events[0]?.source).to(haveCount(1))
        
        expect(events[2]?.change) == ObservableArrayChange.deletes([0])
        expect(events[2]?.source).to(haveCount(0))
    }
}
