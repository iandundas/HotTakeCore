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


public func equal(_ expected: ObservableArrayChange?) -> MatcherFunc<ObservableArrayChange?> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "equal <\(expected)>"
        
        guard let evaluatedActualValue = try actualExpression.evaluate() else {return false}
        guard let concreteActualValue = evaluatedActualValue, let expectedValue = expected else {
            return evaluatedActualValue == nil && expected == nil // if they're both nil, then alright.
        }
        
        switch (concreteActualValue, expectedValue){
        case (.reset, .reset): return true
        case (.beginBatchEditing, .beginBatchEditing): return true
        case (.endBatchEditing, .endBatchEditing): return true
        case let (.inserts(a), .inserts(b)): return a == b
        case let (.deletes(a), .deletes(b)): return a == b
        case let (.updates(a), .updates(b)): return a == b
        case let (.move(a), .move(b)): return a == b
        default:
            fatalError("@id This matcher does not support \(concreteActualValue) vs \(expectedValue) comparisons yet..")
        }
    }
}



//public func equal<T: Equatable>(_ expected: ObservableArrayEvent<T>?) -> MatcherFunc<ObservableArrayEvent<T>?> {
//    return MatcherFunc { actualExpression, failureMessage in
//        failureMessage.postfixMessage = "equal <\(expected)>"
//        
//        guard let evaluatedActualValue = try actualExpression.evaluate() else {return false}
//        guard let concreteActualValue = evaluatedActualValue, let expectedValue = expected else {
//            return evaluatedActualValue == nil && expected == nil // if they're both nil, then alright.
//        }
//        
//        guard concreteActualValue.source.array == expectedValue.source.array else {return false}
//        
//        
//        return MatcherFunc(concreteActualValue) // .equal(concreteActualValue)
//    }
//}

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
        
        datasource.mutations().element(at: 0).bind(to: firstEvent).disposeIn(bag)
        datasource.mutations().element(at: 1).bind(to: secondEvent).disposeIn(bag)
        
        expect(firstEvent.value?.change).to(equal(ObservableArrayChange.reset))
        expect(secondEvent.value?.change).to(beNil())
    }
    
    func testInsertEventIsReceived(){
        let items = [catA, catB]
        datasource = ManualDataSource<Cat>(items: items)

        let firstEvent = ChangesetProperty(nil)
        let secondEvent = ChangesetProperty(nil)
        
        datasource.mutations().element(at: 0).bind(to: firstEvent).disposeIn(bag)
        datasource.mutations().element(at: 1).bind(to: secondEvent).disposeIn(bag)
        
        expect(firstEvent.value?.change).to(equal(ObservableArrayChange.reset))
        expect(firstEvent.value?.dataSource.array).to(equal(items))
        expect(secondEvent.value?.change).to(beNil())
    }

    func testDeleteEventIsReceived(){
        let items = [catA, catB]
        datasource = ManualDataSource<Cat>(items: items)
       
        let secondEvent = ChangesetProperty(nil)
        datasource.mutations().element(at: 1).bind(to: secondEvent).disposeIn(bag)
        
        let thirdEvent = ChangesetProperty(nil)
        datasource.mutations().element(at: 2).bind(to: thirdEvent).disposeIn(bag)
        
        let fourthEvent = ChangesetProperty(nil)
        datasource.mutations().element(at: 3).bind(to: fourthEvent).disposeIn(bag)

        datasource.replaceItems(items: [])

        expect(secondEvent.value?.change).to(equal(ObservableArrayChange.beginBatchEditing))
        expect(thirdEvent.value?.change).to(equal(ObservableArrayChange.deletes([0,1])))
        expect(fourthEvent.value?.change).to(equal(ObservableArrayChange.endBatchEditing))
    }
    

    func testBasicInsertBindingWhereObserverIsBoundBeforeInsert() {
        datasource = ManualDataSource<Cat>(items: [])
        
        let firstChangeset = ChangesetProperty(nil)
        datasource.mutations().element(at: 0).bind(to: firstChangeset)
        
        let thirdChangeset = ChangesetProperty(nil)
        datasource.mutations().element(at: 2).bind(to: thirdChangeset)
        
        datasource.replaceItems(items: [catA])
        
        expect(firstChangeset.value?.source).to(beEmpty())
        expect(thirdChangeset.value?.source).to(haveCount(1))
        expect(thirdChangeset.value?.change).to(equal(ObservableArrayChange.inserts([0])))
    }

    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithoutDelay() {
        datasource = ManualDataSource<Cat>(items: [])
        
        datasource.replaceItems(items: [catA])
        
        let firstChangeset = ChangesetProperty(nil)
        datasource.mutations().element(at: 0).bind(to: firstChangeset)
        
        let secondChangeset = ChangesetProperty(nil)
        datasource.mutations().element(at: 1).bind(to: secondChangeset)
        
        expect(firstChangeset.value?.source).to(haveCount(1))
        expect(firstChangeset.value?.change).to(equal(ObservableArrayChange.reset))
        
        expect(secondChangeset.value).to(beNil())
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
        
        let firstChangeset = ChangesetProperty(nil)
        datasource.mutations().element(at: 0).bind(to: firstChangeset)
        
        let thirdChangeset = ChangesetProperty(nil)
        datasource.mutations().element(at: 2).bind(to: thirdChangeset)
        
        datasource.replaceItems(items: [catA, catB])
        
        expect(firstChangeset.value?.source).to(haveCount(1))
        // expect(firstChangeset.value?.inserts.count).to(equal(0))
        
        expect(thirdChangeset.value?.source).to(haveCount(2))
        expect(thirdChangeset.value?.change).to(equal(ObservableArrayChange.inserts([1])))
    }
    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithoutDelayAndAnItemIsAlreadyAdded() {
        datasource = ManualDataSource<Cat>(items: [catA])
        
        datasource.replaceItems(items:[catA, catB])
        
        let firstChangeset = ChangesetProperty(nil)
        datasource.mutations().element(at: 0).bind(to: firstChangeset)
        
        let secondChangeset = ChangesetProperty(nil)
        datasource.mutations().element(at: 1).bind(to: secondChangeset)
        
        expect(firstChangeset.value?.source).to(haveCount(2))
        expect(firstChangeset.value?.change).to(equal(ObservableArrayChange.reset))
        
        expect(secondChangeset.value).to(beNil())
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
    
    func testBasicDeleteWhereColletionEmptiesAfterObservingBeforehand() {
        datasource = ManualDataSource<Cat>(items: [catA])
        
        let firstChangeset = ChangesetProperty(nil)
        self.datasource.mutations().element(at: 0).bind(to: firstChangeset)
        let thirdChangeset = ChangesetProperty(nil)
        self.datasource.mutations().element(at: 2).bind(to: thirdChangeset)
        
        datasource.replaceItems(items: [])
        
        expect(firstChangeset.value?.source).to(haveCount(1))
        
        expect(thirdChangeset.value?.source).to(haveCount(0))
        expect(thirdChangeset.value?.change).to(equal(ObservableArrayChange.deletes([0])))
    }
    

//    func testBasicUpdateWhereCollectionIsObservingBeforehandAfterDelay() {
//        datasource = ManualDataSource<Cat>(items: [catA])
//        
//        datasource.mutations().observeNext {event in
//            print("event: \(event)")
//        }
//        let firstChangeset = ChangesetProperty(nil)
//        self.datasource.mutations().element(at: 0).bind(to: firstChangeset)
//        let secondChangeset = ChangesetProperty(nil)
//        self.datasource.mutations().element(at: 1).bind(to: secondChangeset)
//        
//        Queue.main.after(1){
//            self.catA.name = "miss miggins"
//            self.datasource.replaceItems([self.catA])
//        }
//        
//        expect(firstChangeset.value?.collection.count).to(equal(1))
//        expect(firstChangeset.value?.inserts.count).to(equal(0))
//        expect(firstChangeset.value?.updates.count).to(equal(0))
//        expect(firstChangeset.value?.deletes.count).to(equal(0))
//        
//        expect(secondChangeset.value?.collection.count).to(equal(1))
//        expect(secondChangeset.value?.inserts.count).to(equal(0))
//        expect(secondChangeset.value?.updates.count).to(equal(1))
//        expect(secondChangeset.value?.deletes.count).to(equal(0))
//        
//    }
}
