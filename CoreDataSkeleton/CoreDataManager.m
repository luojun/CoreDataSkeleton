//
//  CoreDataManager.m
//  CoreDataSkeleton
//
//  Created by Jun Luo on 2014-07-06.
//  Copyright (c) 2014 Jun Luo. All rights reserved.
//

#import "CoreDataManager.h"

@interface CoreDataManager ()

@property (nonatomic,strong,readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) NSURL *modelURL;
@property (nonatomic,strong) NSURL *storeURL;

@end

@implementation CoreDataManager

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

static CoreDataManager *_defaultManager;
static NSManagedObjectModel *_defaultModel;
static NSPersistentStoreCoordinator *_defaultSqliteCoordinator;
static NSManagedObjectContext *_defaultWriterContext;
static NSManagedObjectContext *_defaultMainContext;

+ (void)setupDefaultsWithModelURL:(NSURL *)modelURL storeURL:(NSURL *)storeURL
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _defaultManager = [[CoreDataManager alloc] initWithModelURL:modelURL storeURL:storeURL];
        _defaultModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        _defaultSqliteCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_defaultModel];
        NSError* error;
        [_defaultSqliteCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
        _defaultWriterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _defaultWriterContext.persistentStoreCoordinator = _defaultSqliteCoordinator;
        _defaultMainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _defaultMainContext.parentContext = _defaultWriterContext;
    });
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

@end