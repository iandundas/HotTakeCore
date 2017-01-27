//
//  Bond.swift
//  HotTakeCore
//
//  Created by Ian Dundas on 25/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import Foundation
import Bond
import ReactiveKit

// Stop-gap until this is resolved: 
// https://github.com/ReactiveKit/Bond/issues/376

extension ObservableArray where Item: Equatable {
    
    public func sorted(by sorter: @escaping (Item, Item) -> Bool) -> Signal<ObservableArrayEvent<Item>, NoError>{
        return Signal { (observer: AtomicObserver<ObservableArrayEvent<Item>, NoError>) -> Disposable in
            
            let disposable = DisposeBag()
            var differ: MutableObservableArray<Item>! // Stores a sorted version of the datasource, generates diff events
            
            self.observeNext(with: { (latestUpdate: ObservableArrayEvent<Item>) in
                let sorted = latestUpdate.dataSource.array.sorted(by: sorter)
                
                if differ == nil {
                    differ = MutableObservableArray<Item>(latestUpdate.dataSource.array)
                    differ
                        // we don't want to pass on the first .reset event containing the unsorted array
                        .skip(first: 1)
                        // pass events from the differ to the signal observer:
                        .observeNext(with: observer.next).dispose(in: disposable)
                    
                    // create our own .reset event instead, with the sorted array:
                    observer.next(ObservableArrayEvent(change: .reset, source: ObservableArray(sorted)))
                }
                else {
                    guard let differ = differ else {return}
                    
                    // Replace contents of differ to generate diff event for observer:
                    differ.replace(with: sorted, performDiff: true)
                }
            }).dispose(in: disposable)
            
            return disposable
        }
    }
}
