//
//  CoreDataManager.m
//  CoreDataSkeleton (https://github.com/luojun/CoreDataSkeleton)
//
//  Created by Jun Luo on 2014-07-06.
//  Copyright (c) 2014 Jun Luo. All rights reserved.
//

#import "CoreDataHelper.h"

@interface CoreDataHelper ()

@property (nonatomic,strong,readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) NSURL *modelURL;
@property (nonatomic,strong) NSURL *storeURL;

@end

@implementation CoreDataHelper

#pragma mark - defaults

static NSURL *_defaultStoreURL;
static NSURL *_defaultModelURL;

// This set up follows the pattern discussed here: http://www.slideshare.net/xzolian/core-data-with-multiple-managed-object-contexts
// and here: http://www.cocoanetics.com/2012/07/multi-context-coredata/, attributed to Marcus Zarra.
// However, see http://floriankugler.com/blog/2013/4/29/concurrent-core-data-stack-performance-shootout for performance comparison.

static NSManagedObjectModel *_defaultModel;
static NSPersistentStoreCoordinator *_defaultSqliteCoordinator;
static NSManagedObjectContext *_defaultWriterContext;
static NSManagedObjectContext *_defaultMainContext;

static NSPersistentStoreCoordinator *_defaultMemoryCoordinator;
static NSManagedObjectContext *_defaultScratchMainContext;

+ (void)setupDefaultsWithModelURL:(NSURL *)modelURL storeURL:(NSURL *)storeURL
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _defaultModelURL = modelURL;
        _defaultStoreURL = storeURL;
        _defaultModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        _defaultSqliteCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_defaultModel];
        NSError* error;
        [_defaultSqliteCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
        _defaultWriterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _defaultWriterContext.persistentStoreCoordinator = _defaultSqliteCoordinator;
        _defaultMainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _defaultMainContext.parentContext = _defaultWriterContext;
        _defaultMainContext.undoManager = [[NSUndoManager alloc] init];
    });
}

+ (void)setupDefaultsWithModelName:(NSString *)modelName storeName:(NSString *)storeName
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
    NSURL *storeURL = [[CoreDataHelper applicationDocumentsDirectory] URLByAppendingPathComponent:storeName];
    [CoreDataHelper setupDefaultsWithModelURL:modelURL storeURL:storeURL];
}

+ (NSPersistentStoreCoordinator *)defaultSqliteCoordinator
{
    return _defaultSqliteCoordinator;
}

+ (NSManagedObjectContext *)defaultWriterContext
{
    return _defaultWriterContext;
}

+ (NSManagedObjectContext *)defaultMainContext
{
    return _defaultMainContext;
}

+ (NSManagedObjectContext *)workerContext
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = _defaultMainContext;
    return context;
}

+ (NSManagedObjectContext *)defaultScratchMainContext
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _defaultMemoryCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_defaultModel];
        NSError* error;
        [_defaultMemoryCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
        _defaultScratchMainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_defaultScratchMainContext setPersistentStoreCoordinator:_defaultMemoryCoordinator];
    });
    return _defaultScratchMainContext;
}

+ (NSManagedObjectContext *)scratchWorkerContext
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = [CoreDataHelper defaultScratchMainContext];
    return context;
}

#pragma mark - convenience

+ (BOOL)itemExistsWithValue:(NSString *)value forAttribute:(NSString *)attributeName inEntity:(NSString *)entityName forContext:(NSManagedObjectContext *)context
{
    NSError * error;
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:entityName
                                   inManagedObjectContext:context]];
    [request setFetchLimit:1];
    NSString *predicateFormatString = [NSString stringWithFormat:@"%@ == %%@", attributeName];
    [request setPredicate:[NSPredicate predicateWithFormat:predicateFormatString, value]];
    NSUInteger count = [context countForFetchRequest:request error:&error];
    if (count == NSNotFound) {
        NSLog(@"Error: %@", error);
        return NO;
    }
    return (count != 0);
}


+ (void)saveMainContext:(NSManagedObjectContext *)mainContext
{
    NSAssert(mainContext == [CoreDataHelper defaultMainContext], @"Context must be the default main context");
    [mainContext performBlock:^{
        NSError *error = nil;
        if (![mainContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        [mainContext.parentContext performBlock:^{
            NSError *error = nil;
            if (![mainContext.parentContext save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }];
    }];
}

+ (void)saveWorkerContext:(NSManagedObjectContext *)workerContext
{
    NSAssert(workerContext.parentContext == [CoreDataHelper defaultMainContext], @"Worker context must be child of the default main context");
    NSError *error = nil;
    if (![workerContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [CoreDataHelper saveMainContext:workerContext.parentContext];
}

+ (void)saveScratchWorkerContext:(NSManagedObjectContext *)scratchWorkerContext
{
    NSAssert(scratchWorkerContext.parentContext == [CoreDataHelper defaultScratchMainContext], @"Worker context must be child of the default scratch main context");
    NSError *error = nil;
    if (![scratchWorkerContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - app's documents directory

+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end