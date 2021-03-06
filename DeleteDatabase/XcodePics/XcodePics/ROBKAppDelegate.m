//
//  ROBKAppDelegate.m
//  XcodePics
//
//  Created by Kris Markel on 3/3/13.
//  Copyright (c) 2013 Kris Markel. See License.txt for details.
//

#import "ROBKAppDelegate.h"

#import "MBProgressHUD.h"
#import "ROBKCoreDataCoordinator.h"
#import "ROBKDataLoader.h"

@interface ROBKAppDelegate	()

@property (nonatomic, strong) ROBKDataLoader *dataLoader;

@end

@implementation ROBKAppDelegate

+ (ROBKAppDelegate *)appDelegate
{
	return (ROBKAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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

- (void) reloadData
{
	 if (!self.dataLoader) {
		  self.dataLoader = [ROBKDataLoader new];
	 }

	 NSURL *XcodePicsURL = [NSURL URLWithString:@"http://picasaweb.google.com/data/feed/api/all?kind=photo&q=xcode&alt=json"];
	 [self.dataLoader loadJSONFromURL:XcodePicsURL];
}

- (void) deleteDatabaseFile
{
	 MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
	 hud.dimBackground = YES;
	 hud.labelText = NSLocalizedString(@"Deleting the database", nil);
	 hud.minShowTime = 3.0;
	 
	 [[ROBKCoreDataCoordinator sharedCoordinator] deleteDataStore:^(BOOL success) {
		  if (success) {
				NSLog(@"Database deleted");
		  }
		  dispatch_async(dispatch_get_main_queue(), ^{
				[hud hide:YES];
		  });
	 }];
}

@end
