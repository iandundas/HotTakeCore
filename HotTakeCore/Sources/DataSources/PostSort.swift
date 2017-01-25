//
//  PostSort.swift
//  HotTakeCore
//
//  Created by Ian Dundas on 30/11/2016.
//  Copyright © 2016 Ian Dundas. All rights reserved.
//

import Foundation
import ReactiveKit
import Bond


/* Wraps an existing DataSource allowing a sort order to be applied to it */
public class PostSortDataSource<Item: Equatable>: DataSourceType {
    
    public func items() -> [Item] {
        let items: [Item] = collection.filter{_ in true}
        return items.sorted(by: isOrderedBefore)
    }
    
    public func mutations() -> Signal1<ObservableArrayEvent<Item>>{
        return collection.sorted(by: isOrderedBefore)
    }
    
    private let internalDataSource: AnyDataSource<Item>
    private let collection: MutableObservableArray<Item>
    private let isOrderedBefore: (Item, Item) -> Bool
    
    public init(datasource: AnyDataSource<Item>, isOrderedBefore: @escaping (Item, Item)->Bool){
        self.internalDataSource = datasource
        self.isOrderedBefore = isOrderedBefore
        
        collection = MutableObservableArray<Item>(datasource.items())
    
        internalDataSource.mutations().bind(to: collection)
    }
}


public extension DataSourceType{

  public func postSort(isOrderedBefore: @escaping (ItemType, ItemType) -> Bool) -> AnyDataSource<ItemType>{
    let wrapper = AnyDataSource(self)
    let postsort = PostSortDataSource(datasource: wrapper, isOrderedBefore: isOrderedBefore)
    return AnyDataSource(postsort)
  }
}
