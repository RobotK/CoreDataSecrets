//
//  ROBKAppDelegate.m
//  XcodePics
//
//  Created by Kris Markel on 3/3/13.
//  Copyright (c) 2013 RobotK. All rights reserved.
//

#import "ROBKAppDelegate.h"

#import "XcodePicsCoreDataLibrary/DCTCoreDataStack+ROBKAdditions.h"
#import "XcodePicsCoreDataLibrary/ROBKDatabaseUpdater.h"

@interface ROBKAppDelegate ()

@property (nonatomic, strong) ROBKDatabaseUpdater *databaseUpdater;

@end

@implementation ROBKAppDelegate

+ (ROBKAppDelegate *)appDelegate
{
	return (ROBKAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void) dealloc
{
	// Technically not needed, but included for completeness.
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// If there's no database file in the data directory, copy the one from the bundle.
	NSURL *databaseURL = [DCTCoreDataStack databaseURL];
	// Intentionally ignoring the error info here.
	if (![databaseURL checkResourceIsReachableAndReturnError:NULL]) { 
		NSURL *includedDatabaseURL = [[NSBundle mainBundle] URLForResource:@"XcodePics" withExtension:@"sqlite"];
		NSError * __autoreleasing fileCopyError;
		BOOL fileCopied = [[NSFileManager defaultManager] copyItemAtURL:includedDatabaseURL toURL:databaseURL error:&fileCopyError];
		if (!fileCopied) {
			NSLog(@"Error copying file. %@", fileCopyError);
		}
	}

	self.coreDataStack = [DCTCoreDataStack sharedCoreDataStack];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSaveNotificationHandler:) name:NSManagedObjectContextDidSaveNotification object:nil];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		self.databaseUpdater = [ROBKDatabaseUpdater new];
		NSURL *flickrXcodeURL = [NSURL URLWithString:@"http://picasaweb.google.com/data/feed/api/all?kind=photo&q=xcode&alt=json"];
		[self.databaseUpdater loadJSONFromURL:flickrXcodeURL];
	});

	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Notification handlers

- (void)didSaveNotificationHandler:(NSNotification *)notification
{
	NSLog(@"Saved!");

	NSManagedObjectContext *moc = (NSManagedObjectContext *)notification.object;

	if (moc.persistentStoreCoordinator == self.coreDataStack.managedObjectContext.persistentStoreCoordinator) {

		dispatch_async(dispatch_get_main_queue(), ^{
			[self.coreDataStack.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
		});

	}
}

@end
