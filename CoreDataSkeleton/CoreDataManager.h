//
//  CoreDataManager.h
//  CoreDataSkeleton
//
//  Created by Jun Luo on 2014-07-06.
//  Copyright (c) 2014 Jun Luo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataManager : NSObject

+ (void)setupDefaultsWithModelURL:(NSURL *)modelURL storeURL:(NSURL *)storeURL;
+ (NSPersistentStoreCoordinator *)defaultSqliteCoordinator;
+ (NSManagedObjectContext *)defaultWriterContext;
+ (NSManagedObjectContext *)defaultMainContext;
+ (NSManagedObjectContext *)tempContext;

+ (BOOL)itemExistsWithValue:(NSString *)value forAttribute:(NSString *)attributeName inEntity:(NSString *)entityName forContext:(NSManagedObjectContext *)context;

@end
