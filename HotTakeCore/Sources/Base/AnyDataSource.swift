//
//  AnyDataSoure.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 04/05/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import UIKit
import ReactiveKit
import Bond

private class _AnyDataSourceBoxBase<T: Equatable>: DataSourceType{
    func items() -> Array<T>{
        fatalError()
    }

    func mutations() -> Signal1<ObservableArrayEvent<T>> {
        fatalError()
    }
}

private class _AnyDataSourceBox<DataSource: DataSourceType>: _AnyDataSourceBoxBase<DataSource.ItemType>{
    typealias ItemType = DataSource.ItemType

    let base: DataSource

    init(_ base: DataSource) {
        self.base = base
    }

    override func items() -> Array<ItemType>{
        return base.items()
    }

    override func mutations() -> Signal1<ObservableArrayEvent<ItemType>> {
        return base.mutations()
    }
}


public final class AnyDataSource<Element: Equatable>: DataSourceType{

    private let box: _AnyDataSourceBoxBase<Element>

    public func items() -> Array<Element>{
        return box.items()
    }

    public func mutations() -> Signal1<ObservableArrayEvent<Element>> {
        return box.mutations()
    }

    public init<S: DataSourceType>(_ base: S) where S.ItemType == Element {
        self.box = _AnyDataSourceBox(base)
    }
}
