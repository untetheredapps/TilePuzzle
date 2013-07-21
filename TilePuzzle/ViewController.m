//
//  ViewController.m
//  TilePuzzle
//
//  Created by Dan Ratcliff on 7/20/13.
//  Copyright (c) 2013 Untethered Apps LLC. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TilesForRect.h"
#import "Tile.h"

#define MAX_ROWS 2
#define MAX_COLUMNS 2

#define BORDER_THICKNESS 5.0

#define BORDER_COLOR lightGrayColor

@interface ViewController ()

@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, strong) UIImageView *sourceImageView;
@property (nonatomic, strong) UIView *tilesContainerView;
@property (nonatomic, strong) UIView *tilesContainerBorderView;
@property (nonatomic, strong) TilesForRect *tilesForRect;

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
    self.sourceImage = [UIImage imageNamed:@"globe.jpg"];
    self.sourceImageView = [[UIImageView alloc] initWithImage:self.sourceImage];
    self.sourceImageView.center = CGPointMake(roundf(self.view.bounds.size.width / 2), roundf(self.view.bounds.size.height / 2));
    [self.view addSubview:self.sourceImageView];
    
    [self initModelForNewGame];
    [self refreshViewForModel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private methods

- (void)initModelForNewGame {
    self.tilesForRect = [[TilesForRect alloc] initWithTilesForMaxRows:MAX_ROWS  maxColumns:MAX_COLUMNS];
    NSLog(@"After init, tilesForRect:%@", self.tilesForRect);
    
    [self.tilesForRect randomizeTileLocations];
    NSLog(@"After randomize, tilesForRect:%@", self.tilesForRect);
    
    Tile *tile = [self.tilesForRect getRandomTile];
    tile.hidden = YES;
    NSLog(@"After hiding one, tilesForRect:%@", self.tilesForRect);  
}

- (void)refreshViewForModel {
    // Clean up from before.
    [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // Background is a little bigger than container to keep outer borders same as inner borders.
    self.tilesContainerBorderView = [[UIView alloc] initWithFrame:CGRectInset(self.sourceImageView.frame, - BORDER_THICKNESS, - BORDER_THICKNESS)];
    self.tilesContainerBorderView.backgroundColor = [UIColor BORDER_COLOR];
    [self.view addSubview:self.tilesContainerBorderView];
    
    self.tilesContainerView = [[UIView alloc] initWithFrame:self.sourceImageView.frame];
    self.tilesContainerView.backgroundColor = [UIColor BORDER_COLOR];
    [self.view addSubview:self.tilesContainerView];
    
    CGFloat sourceWidth = self.sourceImageView.bounds.size.width;
    CGFloat sourceHeight = self.sourceImageView.bounds.size.height;
    
    CGFloat tileWidth = sourceWidth / MAX_COLUMNS;
    CGFloat tileHeight = sourceHeight / MAX_ROWS;
    
    // Create tiles.
    for (NSUInteger row = 0; row < MAX_ROWS; row ++) {
        for (NSUInteger column = 0; column < MAX_COLUMNS; column++) {
            //Tile *tile = [self.tilesForRect getTileForRow:row column:column];
            UIImageView *tileImageView = [[UIImageView alloc] initWithImage:self.sourceImage];
            
            // Tile frame corresponds to row and column.
            CGRect frameRect;
            frameRect.size.width = roundf(tileWidth - BORDER_THICKNESS * 2.0);
            frameRect.size.height = roundf(tileHeight - BORDER_THICKNESS * 2.0);
            frameRect.origin.x = roundf(row * tileWidth + BORDER_THICKNESS);
            frameRect.origin.y = roundf(column * tileHeight + BORDER_THICKNESS);
            tileImageView.frame = frameRect;
            
            // Tile contents correspond to row and column (for now).
            CGRect cropRect = frameRect;
            CGImageRef imageRef = CGImageCreateWithImageInRect([self.sourceImage CGImage], cropRect);
            [tileImageView setImage:[UIImage imageWithCGImage:imageRef]];
            CGImageRelease(imageRef);

            [self.tilesContainerView addSubview:tileImageView];
        }
    }
}

@end
