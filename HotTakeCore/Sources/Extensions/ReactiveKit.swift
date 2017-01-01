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

public extension ObservableArrayEvent{

    @available(*, deprecated: 1.0, message: "Use resetted instead (and try to phase out usage)")
    var hasNoMutations: Bool{
        return resetted
    }
    
    var resetted: Bool {
        guard case .reset = change else { return false }
        return true
    }
}
