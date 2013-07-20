//
//  ViewController.m
//  TilePuzzle
//
//  Created by Dan Ratcliff on 7/20/13.
//  Copyright (c) 2013 Untethered Apps LLC. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

@property (nonatomic, strong) UIImageView *sourceImageView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Set the background to a top-light gray to bottom-dark gray gradient.
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    UIColor *topLightGrayColor = [UIColor colorWithRed:125/255.0 green:125/255.0 blue:125/255.0 alpha:1];
    UIColor *bottomDarkGrayColor = [UIColor colorWithRed:33/255.0 green:33/255.0 blue:33/255.0 alpha:1];
    gradient.colors = [NSArray arrayWithObjects:(id)topLightGrayColor.CGColor, (id)bottomDarkGrayColor.CGColor, nil];
    [self.view.layer addSublayer:gradient];
}

- (void)viewWillAppear:(BOOL)animated {
    self.sourceImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"globe.jpg"]];
    self.sourceImageView.center = CGPointMake(roundf(self.view.bounds.size.width / 2), roundf(self.view.bounds.size.height / 2));
    [self.view addSubview:self.sourceImageView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
