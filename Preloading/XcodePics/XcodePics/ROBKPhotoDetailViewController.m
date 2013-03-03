//
//  ROBKPhotoDetailViewController.m
//  XcodePics
//
//  Created by Kris Markel on 3/3/13.
//  Copyright (c) 2013 RobotK. All rights reserved.
//

#import "ROBKPhotoDetailViewController.h"

#import "ROBKPhoto.h"

@interface ROBKPhotoDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

- (void)configureView;
@end

@implementation ROBKPhotoDetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_photo != newDetailItem) {
        _photo = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.photo) {
		 self.detailDescriptionLabel.text = self.photo.text;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
