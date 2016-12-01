# HotTake

_Current release: v0.9.1_

HotTake provides a reactive collection that allows Equatable objects to be hot-swapped on the fly, providing a changeset of what changed.


HotTake provides a reactive collection with a backing datasource that can be "hot-swapped" on the fly. 

For example, a Realm Result of `Cat` objects could be swapped out for a static array of `Cat` objects, and observers would receive the diff of what changed (and what did not). 

It also supports notifications bubbling up from the datasource itself - for example, the Realm datasource implements Realm Notifications, thus passing the changeset from your Realm itself.





For example, using the Realm adapter, you might do the following:

- Plug in a Realm resultset:
- Insert a new item
- Receive the change
- Swap in a specific Array of Cats, separate to the Realm result
- Receive the diff


Note: you must provide a sorted RealmQuery, because [warning from realm]


### Requirements:

- Xcode 8
- Swift 2.3
- iOS only, currently

### Installation:

#### Carthage:
- Add the following line to your Cartfile:

`github "iandundas/HotTakeRealm"`

- Run the following;

`carthage update --toolchain com.apple.dt.toolchain.Swift_2_3 --platform iOS`s

- Add the built frameworks to your project as described [on Carthage](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos), as well as adding each to the Embed Frameworks build phase.
 

#### Cocoapods
_coming soon_
