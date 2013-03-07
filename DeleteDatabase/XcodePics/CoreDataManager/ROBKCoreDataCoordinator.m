//
//  ROBKCoreDataCoordinator.m
//  XcodePicsWithDelete
//
//  Created by Kris Markel on 3/7/13.
//  Copyright (c) 2013 RobotK. All rights reserved.
//

#import "ROBKCoreDataCoordinator.h"

#import "XCodePicsCoreDataLibrary/DCTCoreDataStack+ROBKAdditions.h"

NSString * const ROBKCoordinatorDataUpdateNotification = @"ROBKCoordinatorDataUpdateNotification";
NSString * const ROBKCoordinatorChangedObjectsKey = @"ROBKCoordinatorChangedObjectsKey";
NSString * const ROBKCoordinatorOriginalNotificationUserInfoKey = @"ROBKCoordinatorOriginalNotificationUserInfoKey";

@interface ROBKCoreDataCoordinator ()

@property (nonatomic, strong) NSOperationQueue *coreDataOperationQueue;
@property (nonatomic, strong) DCTCoreDataStack *coreDataStack;

@end

@implementation ROBKCoreDataCoordinator

+ (instancetype) sharedCoordinator
{
    static ROBKCoreDataCoordinator *s_sharedInstance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedInstance = [ROBKCoreDataCoordinator new];
    });

    return s_sharedInstance;
}

#pragma mark - Object Lifecycle

- (id) init
{
    self = [super init];

    if (self) {
        _coreDataOperationQueue = [NSOperationQueue new];
        [_coreDataOperationQueue setName:@"ROBKCoreDataCoordinator CoreDataOperationQueue"];

        _coreDataStack = [DCTCoreDataStack sharedCoreDataStack];
    }

    return self;
}

- (void) dealloc
{
    [_coreDataOperationQueue cancelAllOperations];
}

#pragma mark - Core Data helpers

- (NSManagedObjectContext *) mainThreadContext
{
	 NSAssert([NSThread isMainThread], @"This must be called on the main thread.");
    return self.coreDataStack.managedObjectContext;
}

#pragma mark - Coordinated reads and writes

- (void) coordinateReadingWithBlock:(ROBKCoreDataCoordinatorBlock)block
{
    NSBlockOperation *coordinatedReadOperation = [NSBlockOperation new];

    // Make a weak reference to avoid a retain cycle.
    __weak NSBlockOperation *weakReadOperation = coordinatedReadOperation;

    [coordinatedReadOperation addExecutionBlock:^{

        @autoreleasepool {
            __strong NSBlockOperation *strongReadOperation = weakReadOperation;
            if (!strongReadOperation) {
                return;
            }

            if (strongReadOperation.isCancelled) {
                return;
            }

            NSManagedObjectContext *context = [NSManagedObjectContext new];
				context.persistentStoreCoordinator = self.coreDataStack.persistentStoreCoordinator;
				context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

#ifdef DEBUG
				// Watch for saves occuring during read-only operations and assert if we find one.
				id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:context queue:nil usingBlock:^(NSNotification *note) {
					 NSCAssert(FALSE, @"We should not be saving during a read operation.");
				}];
#endif

				block(context, strongReadOperation);

#ifdef DEBUG
				[[NSNotificationCenter defaultCenter] removeObserver:observer];
#endif

        }

    }];

    [self.coreDataOperationQueue addOperation:coordinatedReadOperation];
}

- (void) coordinateWritingWithBlock:(ROBKCoreDataCoordinatorBlock)block
{
    NSBlockOperation *coordinatedWriteOperation = [NSBlockOperation new];

    // Make a weak reference to avoid a retain cycle.
    __weak NSBlockOperation *weakWriteOperation = coordinatedWriteOperation;

    [coordinatedWriteOperation addExecutionBlock:^{

        @autoreleasepool {
            __strong NSBlockOperation *strongWriteOperation = weakWriteOperation;
            if (!strongWriteOperation) {
                return;
            }

            if (strongWriteOperation.isCancelled) {
                return;
            }

            NSManagedObjectContext *context = [NSManagedObjectContext new];
				context.persistentStoreCoordinator = self.coreDataStack.persistentStoreCoordinator;
				context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;

				id observation = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:context queue:nil usingBlock:^(NSNotification *note) {
					 dispatch_sync(dispatch_get_main_queue(), ^{
						  @autoreleasepool {
								[[self mainThreadContext] mergeChangesFromContextDidSaveNotification:note];

								NSDictionary *originalUserInfo = [note userInfo];
								NSMutableSet *changedObjectsSet = [NSMutableSet setWithSet:[originalUserInfo objectForKey:NSInsertedObjectsKey]];
								[changedObjectsSet addObjectsFromArray:[[originalUserInfo objectForKey:NSUpdatedObjectsKey] allObjects]];
								[changedObjectsSet addObjectsFromArray:[[originalUserInfo objectForKey:NSDeletedObjectsKey] allObjects]];

								NSDictionary *userInfo = @{ROBKCoordinatorOriginalNotificationUserInfoKey : originalUserInfo, ROBKCoordinatorChangedObjectsKey: changedObjectsSet};

								[[NSNotificationCenter defaultCenter] postNotificationName:ROBKCoordinatorDataUpdateNotification object:[self mainThreadContext] userInfo:userInfo];
						  }
					 });
				}];

				block(context, strongWriteOperation);

				[[NSNotificationCenter defaultCenter] removeObserver:observation];
        }

    }];

    // This may block for a while as we wait for other operations to complete, so we want to make sure we're not on the main thread.
    NSAssert(![NSThread isMainThread], @"We're probably blocking the main thread!");

    // Wait for other operations to finish.
    [self.coreDataOperationQueue waitUntilAllOperationsAreFinished];
	 
    [self.coreDataOperationQueue addOperation:coordinatedWriteOperation];
}

@end
