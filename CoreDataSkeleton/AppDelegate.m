//
//  AppDelegate.m
//  CoreDataSkeleton
//
//  Created by Jun Luo on 2014-07-04.
//  Copyright (c) 2014 Jun Luo. All rights reserved.
//

#import "AppDelegate.h"
#import "UserViewController.h"
#import "CoreDataManager.h"

@interface AppDelegate ()
            

@end

@implementation AppDelegate
            
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    splitViewController.delegate = (id)navigationController.topViewController;

    UINavigationController *masterNavigationController = splitViewController.viewControllers[0];
    UserViewController *controller = (UserViewController *)masterNavigationController.topViewController;

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreDataSkeleton" withExtension:@"momd"];
    NSURL *storeURL = [[AppDelegate applicationDocumentsDirectory] URLByAppendingPathComponent:@"CoreDataSkeleton.sqlite"];
    [CoreDataManager setupDefaultsWithModelURL:modelURL storeURL:storeURL];
    controller.managedObjectContext = [CoreDataManager defaultMainContext];
    return YES;
}

#pragma mark - Application's Documents directory

+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
