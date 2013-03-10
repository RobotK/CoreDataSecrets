//
//  DCTCoreDataStack+ROBKAdditions.h
//  XcodePicsCoreDataLibrary
//
//  Created by Kris Markel on 3/4/13.
//  Copyright (c) 2013 Kris Markel. See License.txt for details.
//

#import "DCTCoreDataStack.h"

@interface DCTCoreDataStack (ROBKAdditions)

+ (instancetype) sharedCoreDataStack;
+ (NSURL *) databaseURL;

@end
