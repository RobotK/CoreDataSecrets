//
//  ROBKDataLoader.h
//  XcodePicsWithDelete
//
//  Created by Kris Markel on 3/9/13.
//  Copyright (c) 2013 Kris Markel. See License.txt for details.
//

#import <Foundation/Foundation.h>

/**
 This is the same sa ROBKDatabaseUpdater, but uses ROBKCoreDataCoordinator.
 */

@interface ROBKDataLoader : NSObject

-(void) loadJSONFromURL:(NSURL *)JSONURL;

@end
