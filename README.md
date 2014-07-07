Core Data Skeleton
==================

A simple but complete Core Data app that displays repos of GitHub users

Goal
----

The aim here is a simple but relatively real and complete sample Core Data app. To be relatively complete, it needs to
touch upon how Core Data

1. Interacts with networking,
2. Could be used as structured cache,
3. Deals concurrency,
4. Works with NSFetchedResultsController in a UITableView (or UICollectionView) context, and
5. Handles multiple entities with relationships among them.

A combination of these probably covers most requirements from most simple apps. (What is not demonstrated here is how Core
Data supports manipulation of complext object graph, which is presumably the real deal about Core Data.) To make this 
sample app real enough, the [GitHub API](https://developer.github.com/v3/) is used to pull some basic information about 
repos of GitHub users that one can interactively input into the app. To keep the app simple, other than iOS SDK, no other 
library was used.

Inspiration
-----------

There is a lot of good resources out there. The followiing -- mostly about concurrency -- specifically inspired this project:

1. [A Complete Core Data Application](http://www.objc.io/issue-4/full-core-data-application.html); [GitHub repo here](https://github.com/objcio/issue-4-full-core-data-application)

   One of the best Core Data tutorials. Quite elegant.

2. [Core Data with multiple managed object contexts](http://www.slideshare.net/xzolian/core-data-with-multiple-managed-object-contexts); 
[GitHub repo here](https://github.com/mmorey/CoreDataMultiContext.git)

3. [NSManagedObjectContext’s parentContext](http://benedictcohen.co.uk/blog/archives/308)

   Parent context clearly explained.

4. [Apple's documentation](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html)

   Not the easiest to read. But worth going back again and again.

5. [WWWDC 2014 What's New in Core Data](http://asciiwwdc.com/2014/sessions/225)

   Fair amount of helpful information.

The followng posts were also helpful:

* http://robots.thoughtbot.com/core-data
* http://www.cocoanetics.com/2012/07/multi-context-coredata/
* http://www.cimgf.com/2011/05/04/core-data-and-threads-without-the-headache/


Caveat
------

While the project follows the [three-tier stack](http://www.cocoanetics.com/files/Bildschirmfoto-2012-07-18-um-4.14.55-PM.png) (attributed to Marcus Zarra) in dealing with 
context and concurrency, we should keep in mind these compelling findings:

* [Concurrent Core Data Stacks – Performance Shootout](http://floriankugler.com/blog/2013/4/29/concurrent-core-data-stack-performance-shootout) &
* [Backstage with Nested Managed Object Contexts](http://floriankugler.com/blog/2013/5/11/backstage-with-nested-managed-object-contexts)


iOS 8
-----

The project was done with Xcode 6 and targets iOS 8. While the debugging flag com.apple.CoreData.ConcurrencyDebug 
-- see [WWWDC 2014 What's New in Core Data](http://asciiwwdc.com/2014/sessions/225) -- did seem to be useful, the bug 
reported here:

* [Core Data Conconcurrency Debugging](http://oleb.net/blog/2014/06/core-data-concurrency-debugging/)

The new iOS 8 NSAsynchronousFetchRequst was also tried, but it simply couldn't be made to work in the current iOS 8 beta.
It would be something good to include in a future update to this project.

Known Issues
------------

* The app does not play well with GitHub API's rate limiting.
* Much to be refactored (always the case) Specifically, UserViewController & RepoViewController could be made better.
