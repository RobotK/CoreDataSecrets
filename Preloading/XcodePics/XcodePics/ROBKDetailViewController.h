//
//  ROBKDetailViewController.h
//  XcodePics
//
//  Created by Kris Markel on 3/3/13.
//  Copyright (c) 2013 RobotK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ROBKDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
