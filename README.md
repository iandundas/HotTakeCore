# HotTake

_Current release: v0.9.1_

HotTake builds on the functionality of the `CollectionProperty` type from [ReactiveKit 2](https://github.com/ReactiveKit/ReactiveKit/tree/v2.1.1).

It provides a reactive Collection that is driven by any _observable_ backing datasource (currently supporting Realm, a regular Array and, coming soon, CoreData) which can be "hot-swapped" to another datasource on the fly, providing any observers with a diff of what's changed, and then re-binding to the underlying datasource to continue delivering their own ChangeSets.

## Realm adapter:

For Realm this comes via the [Realm Change Notifications](https://realm.io/docs/swift/latest/#notifications), for CoreData this comes via [NSFetchedResultsController](https://developer.apple.com/reference/coredata/nsfetchedresultscontroller), and for static Arrays this comes from the inherent ability of ReactiveKit's `CollectionProperty` to diff (Equatable-conforming) Arrays.

For example, using the Realm adapter, a Realm query `Result<Cat>` of Cat objects could be plugged into `HotTake.Container`, and bound to a TableView. Any changes to the Realm would be reflected in the tableView automatically. You could then swap the Realm adapter out for a static array of `Cat` objects - any Observers would receive the diff of what changed (and what did not). In turn, you could then swap in any other DataSource containing Cats and it would react to that new collection, providing you a diff.

e.g. you might do the following (_[download example](https://github.com/iandundas/HotTakeDemo)_):

- Plug in a Realm query `Result<Cat>`:
- Insert new items into Realm
- Receive the change (it uses Realm Notifications under the hood), and present on the tableView
- Swap in a specific Array of Cats (in this case, a simple array pulled from Realm for demonstration purposes, but it could be anything), separate to the Realm result
- Receive the diff

<img src="https://cl.ly/0J2q352v263O/Screen%20Recording%202016-12-01%20at%2012.10%20pm.gif" />


## Post-Sort

Datasources can also be chained. For example, there is a PostSort adapter which can be added to the chain to provide your own sorting, separate from the underlying datasource.

This was useful in my app [Tacks](http://tacks.cc), because I needed to sort my Realm query results by distance from my current location, whilst also preserving the ability to observe the array and receive diffs when the underlying dataset changed.

```swift
  // Apply post-sort over the Realm datasource:
  datasource = RealmDataSource(items: result).postSort() { (a: Place, b:Place) in
      return ascending
          ? a.location.distanceFromLocation(currentLocation) < b.location.distanceFromLocation(currentLocation)
          : a.location.distanceFromLocation(currentLocation) > b.location.distanceFromLocation(currentLocation)
  }
```

It is not possible to query Realm like this otherwise.

Note: you must provide a sorted RealmQuery as input to `PostSortDataSource`, because "Note that the order of Results is only guaranteed to stay consistent when the query is sorted." (realm docs)[https://realm.io/docs/swift/latest/#sorting]


### Requirements:

- Xcode 8
- Swift 2.3 (will support v3.0 soon)
- ReactiveKit 2.1.1  (will support v3.0 soon)
- iOS only, currently

### Usage

_more detailed instructions coming soon_

#### Creating your datasource:

__Array DataSource__:

```swift
let arrayDataSource = ManualDataSource<Cat>(items: cats)
```

__Realm DataSource__:

```swift
  let realm = try! RealmSwift.Realm(configuration: RealmSwift.Realm.Configuration(inMemoryIdentifier: sharedRealmID))
  let result = realm.objects(Cat).sorted("miceEaten")
  let realmDataSource = RealmDataSource(items: result)
```

#### Creating your container:

```swift
let container = Container<Cat>(datasource: realmDataSource.eraseType())
```

#### Binding and Observing:

HotTake is built on top of ReactiveKit, so you can use this powerful Functional Reactive library to observe the mutations, and to bind to e.g. a UITableView:


```swift
container.collection.observeNext { (changeset) in
    print("Changeset: \(changeset)\n\n")
}.disposeIn(rBag)

// Bind container to TableView:
container.collection.bindTo(tableView) {
    (indexPath, items, tableView) -> UITableViewCell in

    let item = items[indexPath.row]
    let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
    cell.textLabel?.text = item.name
    return cell

}.disposeIn(rBag)

```


### Installation:

#### Carthage:
- Add the following line to your Cartfile:

`github "iandundas/HotTakeRealm"`

- Run the following;

`carthage update --toolchain com.apple.dt.toolchain.Swift_2_3 --platform iOS`s

- Add the built frameworks to your project as described [on Carthage](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos), as well as adding each to the Embed Frameworks build phase.


#### Cocoapods
_coming soon_
