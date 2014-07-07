//
//  AppDelegate.m
//  CoreDataSkeleton
//
//  Created by Jun Luo on 2014-07-04.
//  Copyright (c) 2014 Jun Luo. All rights reserved.
//

#import "AppDelegate.h"
#import "UserViewController.h"
#import "CoreDataHelper.h"

@interface AppDelegate ()
            

@end

@implementation AppDelegate
            
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // this set up needs to happen first
    [CoreDataHelper setupDefaultsWithModelName:@"CoreDataSkeleton" storeName:@"CoreDataSkeleton.sqlite"];
    
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    splitViewController.delegate = (id)navigationController.topViewController;

    application.applicationSupportsShakeToEdit = YES;

    return YES;
}

#pragma mark - Application's Documents directory

+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
