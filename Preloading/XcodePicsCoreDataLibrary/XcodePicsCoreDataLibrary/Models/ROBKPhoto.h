//
//  ROBKPhoto.h
//  XcodePics
//
//  Created by Kris Markel on 3/3/13.
//  Copyright (c) 2013 RobotK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ROBKPhoto : NSManagedObject

@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSDate * published;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * identifier;

@end
