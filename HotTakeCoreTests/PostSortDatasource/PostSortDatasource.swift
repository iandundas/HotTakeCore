//
//  PostSortDatasource.swift
//  HotTakeCore
//
//  Created by Ian Dundas on 25/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//
import XCTest
import ReactiveKit
import Nimble
import Bond

@testable import HotTakeCore

class PostSortDatasourceTests: XCTestCase {
    
    let catA = Cat(name: "Mr A")
    let catB = Cat(name: "Mr B")
    let catC = Cat(name: "Mr C")
    
    var emptyArray: [Cat]!
    var nonEmptyArray: [Cat]!
    
    let bag = DisposeBag()
    
    var manualDatasource: ManualDataSource<Cat>!
    var postsortDatasource: PostSortDataSource<Cat>!
    
    override func setUp() {
        super.setUp()
        emptyArray = []
        nonEmptyArray = [catA]
    }
    
    override func tearDown() {
        manualDatasource = nil
        postsortDatasource = nil
        bag.dispose()
        super.tearDown()
    }
    
    func testInitialNotificationIsReceived(){
        
        manualDatasource = ManualDataSource<Cat>(items: [catA, catB])
        postsortDatasource = manualDatasource.postSort(isOrderedBefore: { return $0.name < $1.name })
        
        let firstEvent = ChangesetProperty(nil)
        let secondEvent = ChangesetProperty(nil)
        
        postsortDatasource.mutations().element(at: 0).bind(to: firstEvent).dispose(in: bag)
        postsortDatasource.mutations().element(at: 1).bind(to: secondEvent).dispose(in: bag)
        
        expect(firstEvent.value?.change).to(equal(ObservableArrayChange.reset))
        expect(firstEvent.value?.source.array) == [catA, catB]
        expect(secondEvent.value?.change).to(beNil())
    }
    
    func testBasicDeleteWhereColletionEmptiesAfterObservingBeforehand() {
        manualDatasource = ManualDataSource<Cat>(items: [catA])
        postsortDatasource = manualDatasource.postSort(isOrderedBefore: { return $0.name < $1.name })
        
        let events = postsortDatasource.mutations().store()
        
        manualDatasource.replaceItems(items: [])
        
        expect(events[0]?.source).to(haveCount(1))
        expect(events[2]?.source).to(haveCount(0))
        expect(events[2]?.change) == ObservableArrayChange.deletes([0])
    }
}
