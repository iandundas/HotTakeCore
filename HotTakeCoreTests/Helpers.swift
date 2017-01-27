//
//  Helpers.swift
//  HotTakeCore
//
//  Created by Ian Dundas on 30/11/2016.
//  Copyright © 2016 Ian Dundas. All rights reserved.
//

import Foundation
import ReactiveKit
import Bond
import Nimble

typealias ChangesetProperty = ReactiveKit.Property<ObservableArrayEvent<Cat>?>


class EventStore<Item> {
    
    private let signal: SafeSignal<Item>
    private let bag = DisposeBag()
    private var values: [Item] = []
    
    init(signal: SafeSignal<Item>){
        self.signal = signal
        
        signal.observeNext { (next) in
            self.values.append(next)
            }.dispose(in: bag)
    }
    
    subscript(index: Int) -> Item? {
        get {
            guard values.count > index else {return nil}
            return values[index]
        }
    }
}

extension SignalProtocol{
    func store() -> EventStore<Element>{
        return EventStore(signal: self.suppressError(logging: false))
    }
}


public func equal(_ expected: ObservableArrayChange?) -> MatcherFunc<ObservableArrayChange?> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "equal <\(expected)>"
        
        guard let evaluatedActualValue = try actualExpression.evaluate() else {return false}
        guard let concreteActualValue = evaluatedActualValue, let expectedValue = expected else {
            return evaluatedActualValue == nil && expected == nil // if they're both nil, then alright.
        }
        
        return concreteActualValue == expectedValue
    }
}

extension ObservableArrayChange: Equatable {
    public static func ==(a: ObservableArrayChange, b: ObservableArrayChange) -> Bool{
        switch (a,b){
        case (.reset, .reset): return true
        case (.beginBatchEditing, .beginBatchEditing): return true
        case (.endBatchEditing, .endBatchEditing): return true
        case let (.inserts(a), .inserts(b)): return a == b
        case let (.deletes(a), .deletes(b)): return a == b
        case let (.updates(a), .updates(b)): return a == b
        case let (.move(a), .move(b)): return a == b
        default:
            return false
        }
    }
}

