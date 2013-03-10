//
//  ROBKAppDelegate.h
//  XcodePics
//
//  Created by Kris Markel on 3/3/13.
//  Copyright (c) 2013 Kris Markel. See License.txt for details.
//

#import <UIKit/UIKit.h>

@class DCTCoreDataStack;

@interface ROBKAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) DCTCoreDataStack *coreDataStack;

+ (ROBKAppDelegate *)appDelegate;

@end
