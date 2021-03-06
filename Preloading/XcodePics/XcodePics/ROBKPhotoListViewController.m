//
//  ROBKPhotoListViewController.m
//  XcodePics
//
//  Created by Kris Markel on 3/4/13.
//  Copyright (c) 2013 Kris Markel. See License.txt for details.
//

#import "ROBKPhotoListViewController.h"

#import <CoreData/CoreData.h>

#import "XcodePicsCoreDataLibrary/DCTCoreDataStack.h"
#import "XcodePicsCoreDataLibrary/ROBKPhoto+ROBKAdditions.h"

#import "ROBKAppDelegate.h"
#import "ROBKPhotoDetailViewController.h"

@interface ROBKPhotoListViewController () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

// Declare some collection properties to hold the various updates we might get from the NSFetchedResultsControllerDelegate
@property (nonatomic, strong) NSMutableIndexSet *deletedSectionIndexes;
@property (nonatomic, strong) NSMutableIndexSet *insertedSectionIndexes;
@property (nonatomic, strong) NSMutableArray *deletedRowIndexPaths;
@property (nonatomic, strong) NSMutableArray *insertedRowIndexPaths;
@property (nonatomic, strong) NSMutableArray *updatedRowIndexPaths;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation ROBKPhotoListViewController

@synthesize fetchedResultsController=_fetchedResultsController, managedObjectContext=_managedObjectContext;

- (void)awakeFromNib
{
	[super awakeFromNib];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell" forIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@"showDetail"]) {
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		ROBKPhoto *photo = (ROBKPhoto *)[[self fetchedResultsController] objectAtIndexPath:indexPath];
		[[segue destinationViewController] setPhoto:photo];
	}
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController != nil) {
		return _fetchedResultsController;
	}

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:[ROBKPhoto robk_entityName] inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];

	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];

	// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"published" ascending:YES];
	NSArray *sortDescriptors = @[sortDescriptor];

	[fetchRequest setSortDescriptors:sortDescriptors];

	// Edit the section name key path and cache name if appropriate.
	// nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"ROBKPhotoListViewController"];
	aFetchedResultsController.delegate = self;
	_fetchedResultsController = aFetchedResultsController;

	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
		// Replace this implementation with code to handle the error appropriately.
		// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}

	return _fetchedResultsController;
}

- (NSManagedObjectContext *)managedObjectContext
{
	if (_managedObjectContext) {
		return _managedObjectContext;
	}

	_managedObjectContext = [ROBKAppDelegate appDelegate].coreDataStack.managedObjectContext;
	return _managedObjectContext;
}

#pragma mark - NSFetchedResultsControllerDelegate methods

// This implementation taken from http://www.fruitstandsoftware.com/blog/2013/02/uitableview-and-nsfetchedresultscontroller-updates-done-right/

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
	  forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	if (type == NSFetchedResultsChangeInsert) {
		if ([self.insertedSectionIndexes containsIndex:newIndexPath.section]) {
			// If we've already been told that we're adding a section for this inserted row we skip it since it will handled by the section insertion.
			return;
		}

		[self.insertedRowIndexPaths addObject:newIndexPath];
	} else if (type == NSFetchedResultsChangeDelete) {
		if ([self.deletedSectionIndexes containsIndex:indexPath.section]) {
			// If we've already been told that we're deleting a section for this deleted row we skip it since it will handled by the section deletion.
			return;
		}

		[self.deletedRowIndexPaths addObject:indexPath];
	} else if (type == NSFetchedResultsChangeMove) {
		if ([self.insertedSectionIndexes containsIndex:newIndexPath.section] == NO) {
			[self.insertedRowIndexPaths addObject:newIndexPath];
		}

		if ([self.deletedSectionIndexes containsIndex:indexPath.section] == NO) {
			[self.deletedRowIndexPaths addObject:indexPath];
		}
	} else if (type == NSFetchedResultsChangeUpdate) {
		[self.updatedRowIndexPaths addObject:indexPath];
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex
	  forChangeType:(NSFetchedResultsChangeType)type
{
	switch (type) {
		case NSFetchedResultsChangeInsert:
			[self.insertedSectionIndexes addIndex:sectionIndex];
			break;
		case NSFetchedResultsChangeDelete:
			[self.deletedSectionIndexes addIndex:sectionIndex];
			break;
		default:
			; // Shouldn't have a default
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	NSInteger totalChanges = [self.deletedSectionIndexes count] +
	[self.insertedSectionIndexes count] +
	[self.deletedRowIndexPaths count] +
	[self.insertedRowIndexPaths count] +
	[self.updatedRowIndexPaths count];
	if (totalChanges > 50) {
		[self.tableView reloadData];
		return;
	}

	[self.tableView beginUpdates];

	[self.tableView deleteSections:self.deletedSectionIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
	[self.tableView insertSections:self.insertedSectionIndexes withRowAnimation:UITableViewRowAnimationAutomatic];

	[self.tableView deleteRowsAtIndexPaths:self.deletedRowIndexPaths withRowAnimation:UITableViewRowAnimationLeft];
	[self.tableView insertRowsAtIndexPaths:self.insertedRowIndexPaths withRowAnimation:UITableViewRowAnimationRight];
	[self.tableView reloadRowsAtIndexPaths:self.updatedRowIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];

	[self.tableView endUpdates];

	// nil out the collections so their ready for their next use.
	self.insertedSectionIndexes = nil;
	self.deletedSectionIndexes = nil;
	self.deletedRowIndexPaths = nil;
	self.insertedRowIndexPaths = nil;
	self.updatedRowIndexPaths = nil;
}

#pragma mark - Overridden getters

/**
 * Lazily instantiate these collections.
 */

- (NSMutableIndexSet *)deletedSectionIndexes
{
	if (_deletedSectionIndexes == nil) {
		_deletedSectionIndexes = [[NSMutableIndexSet alloc] init];
	}

	return _deletedSectionIndexes;
}

- (NSMutableIndexSet *)insertedSectionIndexes
{
	if (_insertedSectionIndexes == nil) {
		_insertedSectionIndexes = [[NSMutableIndexSet alloc] init];
	}

	return _insertedSectionIndexes;
}

- (NSMutableArray *)deletedRowIndexPaths
{
	if (_deletedRowIndexPaths == nil) {
		_deletedRowIndexPaths = [[NSMutableArray alloc] init];
	}

	return _deletedRowIndexPaths;
}

- (NSMutableArray *)insertedRowIndexPaths
{
	if (_insertedRowIndexPaths == nil) {
		_insertedRowIndexPaths = [[NSMutableArray alloc] init];
	}

	return _insertedRowIndexPaths;
}

- (NSMutableArray *)updatedRowIndexPaths
{
	if (_updatedRowIndexPaths == nil) {
		_updatedRowIndexPaths = [[NSMutableArray alloc] init];
	}

	return _updatedRowIndexPaths;
}

#pragma mark - Helpers

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	ROBKPhoto *photo = (ROBKPhoto *)[self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = photo.title;
	cell.detailTextLabel.text = photo.author;
}

@end
