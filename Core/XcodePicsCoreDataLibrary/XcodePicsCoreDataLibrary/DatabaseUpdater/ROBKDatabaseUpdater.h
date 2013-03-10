//
//  ROBKDatabaseUpdater.h
//  XcodePics
//
//  Created by Kris Markel on 3/3/13.
//  Copyright (c) 2013 Kris Markel. See License.txt for details.
//

#import <Foundation/Foundation.h>

@interface ROBKDatabaseUpdater : NSObject

-(void) loadJSONFromURL:(NSURL *)JSONURL;
-(void) synchronousLoadJSONFromURL:(NSURL *)JSONURL;

@end
