//
//  DCTCoreDataStack+ROBKAdditions.m
//  XcodePicsCoreDataLibrary
//
//  Created by Kris Markel on 3/4/13.
//  Copyright (c) 2013 Kris Markel. See License.txt for details.
//

#import "DCTCoreDataStack+ROBKAdditions.h"

@interface DCTCoreDataStack (ROBKAdditions_private)

+ (instancetype) newCoreDataStack_robk; // We need to keep the new at the betting, so we add the robk suffix at the end to prevent possible method name collisions.

@end


@implementation DCTCoreDataStack (ROBKAdditions_private)

+ (instancetype) newCoreDataStack_robk
{
	// Set up the core data stack.
	NSURL *databaseURL = [[self class] databaseURL];

	NSURL *modelBundleURL = [[NSBundle mainBundle] URLForResource:@"XcodePicsModels" withExtension:@"bundle"];
	NSBundle *modelBundle = [NSBundle bundleWithURL:modelBundleURL];
	NSURL *modelURL = [modelBundle URLForResource:@"XcodePics" withExtension:@"momd"];

	DCTCoreDataStack *coreDataStack = [[DCTCoreDataStack alloc] initWithStoreURL:databaseURL storeType:NSSQLiteStoreType storeOptions:nil modelConfiguration:nil modelURL:modelURL];

	return coreDataStack;
}

@end

@implementation DCTCoreDataStack (ROBKAdditions)

+ (instancetype) sharedCoreDataStack
{
	static id sharedInstace;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstace = [self newCoreDataStack_robk];
	});

	return sharedInstace;
}

+ (NSURL *)databaseURL
{
#if TARGET_OS_IPHONE
	NSArray *libraryDirectories = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
	NSAssert([libraryDirectories count] > 0, @"There should be at least one library directory!");
	NSURL *libraryURL = libraryDirectories[0];
#else
	NSString *currentDirectoryPath = [[NSFileManager defaultManager] currentDirectoryPath];
	NSURL *libraryURL = [NSURL fileURLWithPath:currentDirectoryPath];
#endif

	NSURL *dataDirectoryURL = [libraryURL URLByAppendingPathComponent:@"data"];
	NSError __autoreleasing *dataDirectoryCreationError;
	BOOL dataDirectoryCreated = [[NSFileManager defaultManager] createDirectoryAtURL:dataDirectoryURL withIntermediateDirectories:YES attributes:nil error:&dataDirectoryCreationError];
	if (!dataDirectoryCreated) {
		NSLog(@"Could not create the data directory. %@", dataDirectoryCreationError);
	}
	NSURL *databaseURL = [dataDirectoryURL URLByAppendingPathComponent:@"XcodePics.sqlite"];

	return databaseURL;
}

@end
