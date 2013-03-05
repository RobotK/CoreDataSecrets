//
//  ROBKDatabaseUpdater.m
//  XcodePics
//
//  Created by Kris Markel on 3/3/13.
//  Copyright (c) 2013 RobotK. All rights reserved.
//

#import "ROBKDatabaseUpdater.h"

#import <CoreData/CoreData.h>

#import "DCTCoreDataStack+ROBKAdditions.h"
#import "ROBKPhoto+ROBKAdditions.h"

#import "ESJSONOperation.h"
#import "ISO8601DateFormatter.h"

@interface ROBKDatabaseUpdater ()

@property (nonatomic, strong, readonly) DCTCoreDataStack *coreDataStack;
@property (nonatomic, strong, readonly) NSOperationQueue *downloadQueue;
@property (nonatomic, strong, readonly) ISO8601DateFormatter *dateFormatter;

@end

@implementation ROBKDatabaseUpdater

@synthesize dateFormatter=_dateFormatter, coreDataStack=_coreDataStack;

- (id) init
{
	self = [super init];
	if (self) {
		_downloadQueue = [NSOperationQueue new];
	}
	return self;
}

- (void) dealloc
{
	[_downloadQueue cancelAllOperations];
}

-(void) synchronousLoadJSONFromURL:(NSURL *)JSONURL
{
	NSURLRequest *request = [NSURLRequest requestWithURL:JSONURL];
	NSURLResponse * __autoreleasing response = nil;
	NSError * __autoreleasing downloadError;
	NSData *JSONData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&downloadError];

	if (!JSONData) {
		NSLog(@"Error downloading file. %@", downloadError);
		return;
	}

	NSError * __autoreleasing parsingError;
	id JSON = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&parsingError];
	if (!JSON) {
		NSLog(@"Error parsing the json. %@", parsingError);
		return;
	}

	[self insertJSON:JSON];

	return;
}

- (void)insertJSON:(id)JSON
{
	NSAssert([JSON isKindOfClass:[NSDictionary class]], @"Expecting the root object to be a dictionary.");

	NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	moc.persistentStoreCoordinator = self.coreDataStack.persistentStoreCoordinator;

	[moc performBlockAndWait:^{

		NSDictionary *feed = JSON[@"feed"];

		for (NSDictionary *entry in feed[@"entry"]) {

			NSDictionary *identifierDictionary = entry[@"id"];
			NSString *identifier = identifierDictionary[@"$t"];

			ROBKPhoto *photo = nil;

			NSPredicate *existingPhotoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
			NSFetchRequest *existingPhotoFetchRequest = [NSFetchRequest fetchRequestWithEntityName:[ROBKPhoto robk_entityName]];
			[existingPhotoFetchRequest setPredicate:existingPhotoPredicate];

			NSError * __autoreleasing fetchExistingPhotoError;
			NSArray *existingPhotos = [moc executeFetchRequest:existingPhotoFetchRequest error:&fetchExistingPhotoError];
			if (!existingPhotos) {
				NSLog(@"Error fetching photo with identifier %@. %@", identifier, fetchExistingPhotoError);
			} else {
				if ([existingPhotos count] > 0) {
					NSAssert([existingPhotos count] == 1, @"There should only be at most one photo with this identifier.");
					photo = [existingPhotos lastObject];
				}
			}

			if (!photo) {
				photo = [NSEntityDescription insertNewObjectForEntityForName:[ROBKPhoto robk_entityName] inManagedObjectContext:moc];
				photo.identifier = identifier;
			}

			NSArray *authors = entry[@"author"];
			NSAssert([authors count] > 0, @"Not expecting this array to be emtpy");
			NSDictionary *author = [authors lastObject];
			NSString * authorName = author[@"name"][@"$t"];

			if (![authorName isEqualToString:photo.author])
				photo.author = authorName;

			NSString *photoURLString = entry[@"content"][@"src"];
			if (![photoURLString isEqualToString:photo.url]) {
				photo.url = photoURLString;
			}

			NSString *title = entry[@"title"][@"$t"];
			if (![title isEqualToString:photo.title]) {
				photo.title = title;
			}

			NSString *text = entry[@"summary"][@"$t"];
			if (![text isEqualToString:photo.text]) {
				photo.text = text;
			}

			NSString *publishedString = entry[@"published"][@"$t"];
			if (publishedString && [publishedString length] > 0) {
				NSDate *published = [self.dateFormatter dateFromString:publishedString];
				if (![published isEqualToDate:photo.published]) {
					photo.published = published;
				}
			}

		}

		if ([moc hasChanges]) {
			NSError * __autoreleasing saveError;
			BOOL saved = [moc save:&saveError];
			if (!saved) {
				NSLog(@"Error saving: %@", saveError);
			}
		}

		NSLog(@"Updated!");

	}];
}

- (void) loadJSONFromURL:(NSURL *)JSONURL
{
	NSURLRequest *request = [NSURLRequest requestWithURL:JSONURL];
	ESJSONOperation *getDataOperation = [ESJSONOperation newJSONOperationWithRequest:request success:^(ESJSONOperation *op, id JSON) {

		[self insertJSON:JSON];

	} failure:^(ESJSONOperation *op) {
		// TODO: Handle the failure case.
		NSLog(@"Failure: %@", op.error);
	}];

	[self.downloadQueue addOperation:getDataOperation];
}

#pragma mark - Properties

- (ISO8601DateFormatter *) dateFormatter
{
	if (!_dateFormatter) {
		_dateFormatter = [ISO8601DateFormatter new];
		_dateFormatter.parsesStrictly = YES;
	}

	return _dateFormatter;
}

- (DCTCoreDataStack *) coreDataStack
{
	if (!_coreDataStack) {
		_coreDataStack = [DCTCoreDataStack sharedCoreDataStack];
	}

	return _coreDataStack;
}

@end
