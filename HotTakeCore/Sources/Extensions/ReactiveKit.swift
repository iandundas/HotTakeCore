//
//  ReactiveKit.swift
//  HotTakeCore
//
//  Created by Ian Dundas on 30/11/2016.
//  Copyright © 2016 Ian Dundas. All rights reserved.
//

import Foundation
import ReactiveKit
import Bond

public extension ObservableArrayEvent {
    public init(change: ObservableArrayChange, source: ObservableArray<Item>) {
        self.change = change
        self.source = source
    }
}

public extension ObservableArrayEvent{
    @available(*, deprecated: 1.0, message: "Use resetted instead (and try to phase out usage)")
    var hasNoMutations: Bool{
        return resetted
    }
    
    var resetted: Bool {
        guard case .reset = change else { return false }
        return true
    }
    var affectedCount: Int{
        switch change{
        case .deletes(let array): return array.count
        case .inserts(let array): return array.count
        case .updates(let array): return array.count
        case .move(_, _): fatalError("MOVE IS UNIMPLEMENTED")
        default: return 0
        }
    }
    
    var isSignpost: Bool {
        switch change{
        case .beginBatchEditing: return true
        case .endBatchEditing: return true
        case .reset: return true
        default: return false
        }
    }
}

