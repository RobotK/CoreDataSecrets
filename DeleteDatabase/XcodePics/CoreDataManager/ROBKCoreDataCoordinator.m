//
//  ROBKCoreDataCoordinator.m
//  XcodePicsWithDelete
//
//  Created by Kris Markel on 3/7/13.
//  Copyright (c) 2013 Kris Markel. See License.txt for details.
//

#import "ROBKCoreDataCoordinator.h"

#import "XCodePicsCoreDataLibrary/DCTCoreDataStack+ROBKAdditions.h"

#define LOG_WRITE_TIMES
//#define ASSERT_ON_LONG_WRITES

#ifdef ASSERT_ON_LONG_WRITES

const NSTimeInterval longWriteThresholdInSeconds = 3.0f;

#endif


NSString * const ROBKCoordinatorDataUpdateNotification = @"ROBKCoordinatorDataUpdateNotification";
NSString * const ROBKCoordinatorDatabaseDeletedeNotification = @"ROBKCoordinatorDatabaseDeletedeNotification";

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

            NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
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
#ifdef LOG_WRITE_TIMES
	 NSTimeInterval writingRequestedTimeInterval = [NSDate timeIntervalSinceReferenceDate];
#endif

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

            NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
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

#ifdef LOG_WRITE_TIMES
				NSTimeInterval writingStartedTimeInterval = [NSDate timeIntervalSinceReferenceDate];
				NSTimeInterval secondsFromRequestToStart = writingStartedTimeInterval - writingRequestedTimeInterval;

				NSLog(@"Coordinated writing time from request to start of execution: %f.", secondsFromRequestToStart);
#endif

				block(context, strongWriteOperation);

#ifdef LOG_WRITE_TIMES
				NSTimeInterval writingFinishedTimeInterval = [NSDate timeIntervalSinceReferenceDate];
				NSTimeInterval secondsFromStartToFinish = writingFinishedTimeInterval - writingStartedTimeInterval;
				NSTimeInterval secondsFromRequestToFinish = writingFinishedTimeInterval - writingRequestedTimeInterval;

				NSLog(@"Coordinated writing time from start of execution to finish: %f", secondsFromStartToFinish);
				NSLog(@"Coordinated writing time from request to finish: %f", secondsFromRequestToFinish);

#ifdef ASSERT_ON_LONG_WRITES
				NSCAssert(secondsFromRequestToFinish < longWriteThresholdInSeconds, @"Write interval was too long. Interval: %f. Threshold: %f", secondsFromRequestToFinish, longWriteThresholdInSeconds);
#endif
				
#endif // LOG_WRITE_TIMES
				
				[[NSNotificationCenter defaultCenter] removeObserver:observation];
        }

    }];

    // This may block for a while as we wait for other operations to complete, so we want to make sure we're not on the main thread.
    NSAssert(![NSThread isMainThread], @"We're probably blocking the main thread!");

    // Wait for other operations to finish.
    [self.coreDataOperationQueue waitUntilAllOperationsAreFinished];
	 
    [self.coreDataOperationQueue addOperation:coordinatedWriteOperation];
}

-(void)deleteDataStore:(void(^)(BOOL success))callback
{
	 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

		  BOOL success = NO;

		  [self.coreDataOperationQueue cancelAllOperations];
		  [self.coreDataOperationQueue waitUntilAllOperationsAreFinished];

		  NSURL *databaseFileURL = [DCTCoreDataStack databaseURL];

		  // If the file doesn't exist, we consider the deletion to be a success.
		  BOOL databaseFileExists = [databaseFileURL checkResourceIsReachableAndReturnError:nil]; // Intentionally disregarding the error.

		  if (databaseFileExists) {
				NSError __autoreleasing *deletionError;
				BOOL fileDeleted = [[NSFileManager defaultManager] removeItemAtURL:databaseFileURL error:&deletionError];
				if (!fileDeleted) {
					 NSLog(@"Error deleting the database file. %@", deletionError);
				} else {
					 [self.coreDataStack reset];
					 success = YES;
				}
		  } else {
				success = YES;
		  }

		  if (success) {
				[[NSNotificationCenter defaultCenter] postNotificationName:ROBKCoordinatorDatabaseDeletedeNotification object:nil];
		  }
		  callback(success);
	 });
}

@end
