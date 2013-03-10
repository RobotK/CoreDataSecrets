//
//  ROBKDataLoader.m
//  XcodePicsWithDelete
//
//  Created by Kris Markel on 3/9/13.
//  Copyright (c) 2013 RobotK. All rights reserved.
//

#import "ROBKDataLoader.h"

#import "XCodePicsCoreDataLibrary/ESJSONOperation.h"
#import "XCodePicsCoreDataLibrary/ISO8601DateFormatter.h"
#import "XCodePicsCoreDataLibrary/ROBKPhoto+ROBKAdditions.h"

#import "ROBKCoreDataCoordinator.h"

const NSUInteger ROBKDataLoaderSaveFrequency = 50;

@interface ROBKDataLoader ()

@property (nonatomic, strong, readonly) NSOperationQueue *downloadQueue;
@property (nonatomic, strong, readonly) ISO8601DateFormatter *dateFormatter;

@end

@implementation ROBKDataLoader

@synthesize dateFormatter = _dateFormatter;

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

-(void) loadJSONFromURL:(NSURL *)JSONURL
{
	 NSURLRequest *request = [NSURLRequest requestWithURL:JSONURL];
	 ESJSONOperation *getDataOperation = [ESJSONOperation newJSONOperationWithRequest:request success:^(ESJSONOperation *op, id JSON) {

		  [[ROBKCoreDataCoordinator sharedCoordinator] coordinateWritingWithBlock:^(NSManagedObjectContext *context, NSOperation *operation) {
				if ([operation isCancelled]) {
					 return;
				}

				NSDictionary *feed = JSON[@"feed"];

				NSUInteger updateCount = 0;

				for (NSDictionary *entry in feed[@"entry"]) {

					 if ([operation isCancelled]) {
						  return;
					 }

					 NSDictionary *identifierDictionary = entry[@"id"];
					 NSString *identifier = identifierDictionary[@"$t"];

					 ROBKPhoto *photo = nil;

					 NSPredicate *existingPhotoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
					 NSFetchRequest *existingPhotoFetchRequest = [NSFetchRequest fetchRequestWithEntityName:[ROBKPhoto robk_entityName]];
					 [existingPhotoFetchRequest setPredicate:existingPhotoPredicate];

					 NSError * __autoreleasing fetchExistingPhotoError;
					 NSArray *existingPhotos = [context executeFetchRequest:existingPhotoFetchRequest error:&fetchExistingPhotoError];
					 if (!existingPhotos) {
						  NSLog(@"Error fetching photo with identifier %@. %@", identifier, fetchExistingPhotoError);
					 } else {
						  if ([existingPhotos count] > 0) {
								NSAssert([existingPhotos count] == 1, @"There should only be at most one photo with this identifier.");
								photo = [existingPhotos lastObject];
						  }
					 }

					 if (!photo) {
						  photo = [NSEntityDescription insertNewObjectForEntityForName:[ROBKPhoto robk_entityName] inManagedObjectContext:context];
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

					 if ([operation isCancelled]) {
						  return;
					 }

					 if ([context hasChanges]) {
						  updateCount = updateCount + 1;
						  if (updateCount % ROBKDataLoaderSaveFrequency == 0) {
								// Save periodically so a giant save doesn't cause the UI to hiccup.
								NSError * __autoreleasing saveError;
								BOOL saved = [context save:&saveError];
								if (!saved) {
									 NSLog(@"Error saving: %@", saveError);
								}
						  }
					 }

				}

				if ([operation isCancelled]) {
					 return;
				}

				if ([context hasChanges]) {
					 NSError * __autoreleasing saveError;
					 BOOL saved = [context save:&saveError];
					 if (!saved) {
						  NSLog(@"Error saving: %@", saveError);
					 }
				}
				
				NSLog(@"Updated!");

		  }];

	 } failure:^(ESJSONOperation *op) {
		  // TODO: Handle the failure case.
		  NSLog(@"Failure: %@", op.error);
	 }];

	 // Don't call back on the main queue and use a low priority queue to keep the UI responsive.
	 dispatch_queue_t processingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	 [getDataOperation setCompletionQueue:processingQueue];
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


@end
