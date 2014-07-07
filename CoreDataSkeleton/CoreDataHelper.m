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

- (id)initWithModelURL:(NSURL *)modelURL storeURL:(NSURL *)storeURL
{
    self = [super init];
    if (self) {
        self.storeURL = storeURL;
        self.modelURL = modelURL;
    }
    return self;
}


#pragma mark - defaults

// This set up follows the pattern discussed here: http://www.slideshare.net/xzolian/core-data-with-multiple-managed-object-contexts
// and here: http://www.cocoanetics.com/2012/07/multi-context-coredata/, attributed to Marcus Zarra.
// However, see http://floriankugler.com/blog/2013/4/29/concurrent-core-data-stack-performance-shootout for performance comparison.

static NSManagedObjectModel *_defaultModel;
static NSPersistentStoreCoordinator *_defaultSqliteCoordinator;
static NSManagedObjectContext *_defaultWriterContext;
static NSManagedObjectContext *_defaultMainContext;

+ (void)setupDefaultsWithModelURL:(NSURL *)modelURL storeURL:(NSURL *)storeURL
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
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

+ (NSManagedObjectContext *)tempContext
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = _defaultMainContext;
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

+ (void)saveTempContext:(NSManagedObjectContext *)tempContext
{
    NSAssert(tempContext.parentContext == [CoreDataHelper defaultMainContext], @"Temp context must be child of the default main context");
    NSError *error = nil;
    if (![tempContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [CoreDataHelper saveMainContext:tempContext.parentContext];
}

#pragma mark - app's documents directory

+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end