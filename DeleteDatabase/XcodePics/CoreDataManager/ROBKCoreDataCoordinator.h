//
//  ROBKCoreDataCoordinator.h
//  XcodePicsWithDelete
//
//  Created by Kris Markel on 3/7/13.
//  Copyright (c) 2013 Kris Markel. See License.txt for details.
//

#import <Foundation/Foundation.h>

/**
 Based on the ideas and original implementaion of Rob Rix (@rob_rix) and Jonathan Schwarz (@jschwarz), but converted to use an operation queue rather than GCD so we can cancel tasks.

 This class is used to manage concurrency for Core Data related operations.

 All core data work (basically anything that involves an NSManagedObjectContext) should be done using one of the coordinate* methods, unless it's happening on the main thread.

 Update Notifications:

 If a component needs to be aware when some data has changed, it can listen for the ROBKCoordinatorDataUpdateNotification notification. (This is typically necessary for view controllers that need to redisplay when the underlying data has changed.) The notification's userInfo dictionary keys are described in more detail below, but in general, you need to examine the list of changed objects (using ROBKCoordinatorChangedObjectsKey), and if there's a change you're interested in, update your UI appropriately.

 If you're running in the main thread, the MOC returned by -[ROBKCoreDataCoordinator mainThreadContext] will already have the updated data merged in. If you're operating outside of the main thread, you'll want to get updated data using -[ROBKCoreDataCoordinator coordinateReadingWithBlock:].

 */

/** This notification is fired after any changes have been persisted. The keys for the notification's userInfo dictionary are detailed below. DO NOT rely on this notification being posted on a particular queue or thread. */
extern NSString * const ROBKCoordinatorDataUpdateNotification;

/** This notification is fired after the database file has been deleted. The userinfo dictionary is empty. */
extern NSString * const ROBKCoordinatorDatabaseDeletedeNotification;

/** This returns a set that contains every object that's been inserted, deleted, or updated by the latest core data save. It's useful to determine if there have been any changes to a particular entity type that you're class is interensted in. */
extern NSString * const ROBKCoordinatorChangedObjectsKey;

/** This returns the userInfo dictionary from the original NSManagedObjectContextDidSaveNotification. Details can be found in the NSManagedObjectContext class reference. This is useful if you need to know if particular objects have been specifically inserted, deleted, or changed. */
extern NSString * const ROBKCoordinatorOriginalNotificationUserInfoKey;

typedef void(^ROBKCoreDataCoordinatorBlock)(NSManagedObjectContext *context, NSOperation *operation);

@interface ROBKCoreDataCoordinator : NSObject

+ (instancetype) sharedCoordinator;

/**

 Retuns a managed object context for use on the main thread. In debug mode, it will crash (assert) if called on anything other than the main thread.

 */
- (NSManagedObjectContext *)mainThreadContext;

/**

 Coordinates an asynchronous background read

 Use this method for read-only core data tasks that aren't being done on the main thread. Ideally, all such operations should be done using this method.

 This will run concurrently with other reads, but will block writes until it completes.

 */
-(void)coordinateReadingWithBlock:(ROBKCoreDataCoordinatorBlock)block;

/**

 Coordinates an asynchronous background write.

 Use this method for any core data tasks that require persiting the results that aren't being done on the main thread. Ideally, all such operations will be done using this method.

 This will be run serially with respect to both reads and writes.

 */
-(void)coordinateWritingWithBlock:(ROBKCoreDataCoordinatorBlock)block;


/**
 Asyncrhonously delete the data store file.
 
 You probably don't really want to do this.
 */
-(void)deleteDataStore:(void(^)(BOOL success))callback;

@end
