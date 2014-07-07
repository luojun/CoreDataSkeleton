//
//  DetailViewController.h
//  CoreDataSkeleton
//
//  Created by Jun Luo on 2014-07-04.
//  Copyright (c) 2014 Jun Luo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface RepoViewController : UITableViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) NSManagedObject *detailObject;

@end

