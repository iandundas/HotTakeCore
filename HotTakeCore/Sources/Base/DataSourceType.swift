//
//  DataSource.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 04/05/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import Foundation
import ReactiveKit
import Bond

public protocol DataSourceType {
    associatedtype ItemType : Equatable

    // Access a (currently unsorted) array of items:
    func items() -> [ItemType]

    // Access a feed of mutation events:
    func mutations() -> Signal1<ObservableArrayEvent<ItemType>>

    func encloseInContainer() -> Container<ItemType>
    
    func eraseType() -> AnyDataSource<ItemType>
}

public extension DataSourceType{
    public func encloseInContainer() -> Container<ItemType>{
        let wrapper = AnyDataSource(self)
        let container = Container(datasource: wrapper)
        return container
    }
    
    public func eraseType() -> AnyDataSource<ItemType>{
        return AnyDataSource(self)
    }
}
