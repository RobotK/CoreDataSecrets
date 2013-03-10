//
//  ROBKPhotoDetailViewController.m
//  XcodePics
//
//  Created by Kris Markel on 3/3/13.
//  Copyright (c) 2013 Kris Markel. See License.txt for details.
//

#import "ROBKPhotoDetailViewController.h"

#import "XcodePicsCoreDataLibrary/ESHTTPOperation.h"
#import "XcodePicsCoreDataLibrary/ROBKPhoto.h"

#import "ROBKCoreDataCoordinator.h"

@interface ROBKPhotoDetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *publishedDateLabel;

@property (nonatomic, strong, readonly) NSOperationQueue *downloadQueue;

- (IBAction)composeButtonTapped:(id)sender;

- (void)configureView;
- (void)downloadPhoto;

@end

@implementation ROBKPhotoDetailViewController

@synthesize downloadQueue=_downloadQueue;

#pragma mark - Lifecycle

- (void) dealloc
{
	 [[NSNotificationCenter defaultCenter] removeObserver:self name:ROBKCoordinatorDatabaseDeletedNotification object:nil];
	 [[NSNotificationCenter defaultCenter] removeObserver:self name:ROBKCoordinatorChangedObjectsKey object:nil];
}

#pragma mark - Properties

- (void)setPhoto:(ROBKPhoto *)newPhoto
{
	if (_photo != newPhoto) {
		_photo = newPhoto;

		[self downloadPhoto];

		// Update the view.
		[self configureView];
	}
}

- (NSOperationQueue *)downloadQueue
{
	if (_downloadQueue) {
		return _downloadQueue;
	}

	_downloadQueue = [NSOperationQueue new];
	return _downloadQueue;
}

#pragma mark - View Lifecycle

- (void)awakeFromNib
{
	 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDatabaseDeletedNotification:) name:ROBKCoordinatorDatabaseDeletedNotification object:nil];
	 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataUpdatedNotification:) name:ROBKCoordinatorDataUpdateNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
	[super didMoveToParentViewController:parent];
	if (!parent) {
		// We're being dismissed. Cancel any in progress downloads.
		[self.downloadQueue cancelAllOperations];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)composeButtonTapped:(id)sender {

	 [[ROBKCoreDataCoordinator sharedCoordinator] coordinateWritingWithBlock:^(NSManagedObjectContext *context, NSOperation *operation) {

		  if ([operation isCancelled]) {
				return;
		  }

		  NSError __autoreleasing *existingObjectError;
		  ROBKPhoto *photo = (ROBKPhoto *)[context existingObjectWithID:self.photo.objectID error:&existingObjectError];
		  if (!photo) {
				NSLog(@"Error getting object. %@", existingObjectError);
				return;
		  }

		  photo.published = [NSDate date];

		  if ([context hasChanges]) {
				NSError __autoreleasing *saveError;
				BOOL saved = [context save:&saveError];
				if (!saved) {
					 NSLog(@"Error saving. %@", saveError);
				}
		  }
	 }];

}


#pragma mark - Helpers

- (void)configureView
{
	 // Update the user interface for the detail item.

	 if (self.photo) {
		  self.detailDescriptionLabel.text = self.photo.text;
		  self.publishedDateLabel.text = [NSDateFormatter localizedStringFromDate:self.photo.published dateStyle:kCFDateFormatterShortStyle timeStyle:kCFDateFormatterShortStyle];
	 }
}

- (void)downloadPhoto
{
	[self.downloadQueue cancelAllOperations];

	NSURL *downloadURL = [NSURL URLWithString:self.photo.url];
	NSLog(@"downloadURL: %@", downloadURL);
	NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:downloadURL];
	ESHTTPOperation *downloadOperation = [ESHTTPOperation newHTTPOperationWithRequest:downloadRequest work:^id<NSObject>(ESHTTPOperation *op, NSError * __autoreleasing *error) {

		if (op.error)
		{
			if (error)
				*error = op.error;
			return nil;
		}
		NSData *data = op.responseBody;
		if ([data length] == 0)
		{
			return nil;
		}
		UIImage *image = [UIImage imageWithData:data];
		return image;

	} completion:^(ESHTTPOperation *op) {

		NSError *error = op.error;
		if (error)
		{
			// TODO: Handle error.
			NSLog(@"Error downloading an image. %@", error);
		}
		else
		{
			self.imageView.image = op.processedResponse;
		}

	}];

	[self.downloadQueue addOperation:downloadOperation];
}

#pragma mark - Notification handlers

- (void) handleDataUpdatedNotification:(NSNotification *)notification
{
	 dispatch_async(dispatch_get_main_queue(), ^{
		  if (self.isViewLoaded) {

				// If the current photo is in the list of updated object, update the view.
				NSDictionary *userInfo = [notification userInfo];
				NSSet *changedObjects = [userInfo objectForKey:ROBKCoordinatorChangedObjectsKey];

				NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"SELF.objectID = %@", self.photo.objectID];
				NSSet *changedPhoto = [changedObjects filteredSetUsingPredicate:photoPredicate];
				if ([changedPhoto count] > 0) {
					 // Because the changed have already been merged into the main thread MOC, we just need to reread the photo's properties.
					 [self configureView];
				}

		  }
	 });
}

- (void) handleDatabaseDeletedNotification:(NSNotification *)notification
{
	 dispatch_async(dispatch_get_main_queue(), ^{
		  [self.navigationController popToRootViewControllerAnimated:YES];
	 });
}

@end
