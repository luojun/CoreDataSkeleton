//
//  CoreDataFetcher.h
//  CoreDataSkeleton
//
//  Created by Jun Luo on 2014-07-06.
//  Copyright (c) 2014 Jun Luo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol CoreDataFetcherDelegate

- (void)configureCell:(UITableViewCell *)cell withObject:(NSManagedObject *)object;
- (void)deleteObject:(NSManagedObject *)object;

@end

@interface CoreDataFetcher : NSObject <UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic, weak) id<CoreDataFetcherDelegate> delegate;
@property (nonatomic, copy) NSString* reuseIdentifier;
@property (nonatomic) BOOL paused;

- (id)initWithTableView:(UITableView*)tableView;
- (id)selectedItem;

@end
