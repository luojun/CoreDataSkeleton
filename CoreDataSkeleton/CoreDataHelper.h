//
//  CoreDataManager.h
//  CoreDataSkeleton (https://github.com/luojun/CoreDataSkeleton)
//
//  Created by Jun Luo on 2014-07-06.
//  Copyright (c) 2014 Jun Luo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataHelper : NSObject

+ (void)setupDefaultsWithModelURL:(NSURL *)modelURL storeURL:(NSURL *)storeURL;
+ (void)setupDefaultsWithModelName:(NSString *)modelName storeName:(NSString *)storeName;
+ (NSPersistentStoreCoordinator *)defaultSqliteCoordinator;
+ (NSManagedObjectContext *)defaultWriterContext;
+ (NSManagedObjectContext *)defaultMainContext;
+ (NSManagedObjectContext *)tempContext;

+ (void)saveMainContext:(NSManagedObjectContext *)mainContext;
+ (void)saveTempContext:(NSManagedObjectContext *)tempContext;

+ (BOOL)itemExistsWithValue:(NSString *)value forAttribute:(NSString *)attributeName inEntity:(NSString *)entityName forContext:(NSManagedObjectContext *)context;

@end

