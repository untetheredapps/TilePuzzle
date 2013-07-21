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

#define MAX_ROWS 3
#define MAX_COLUMNS 3

#define BORDER_THICKNESS 5.0

#define BORDER_COLOR lightGrayColor

@interface ViewController ()

@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, strong) UIImageView *sourceImageView;
@property (nonatomic, strong) UIView *tilesContainerView;
@property (nonatomic, strong) UIView *tilesContainerBorderView;
@property (nonatomic, strong) TilesForRect *tilesForRect;
@property (nonatomic, assign) CGFloat tileWidth;
@property (nonatomic, assign) CGFloat tileHeight;

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
    // Establish the source image.
    self.sourceImage = [UIImage imageNamed:@"globe.jpg"];
    self.sourceImageView = [[UIImageView alloc] initWithImage:self.sourceImage];
    self.sourceImageView.center = CGPointMake(roundf(self.view.bounds.size.width / 2), roundf(self.view.bounds.size.height / 2));
    [self.view addSubview:self.sourceImageView];
    
    self.tileWidth = self.sourceImageView.bounds.size.width / MAX_COLUMNS;
    self.tileHeight = self.sourceImageView.bounds.size.height / MAX_ROWS;
    
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
    
    // Establish container view for tiles.
    self.tilesContainerView = [[UIView alloc] initWithFrame:self.sourceImageView.frame];
    self.tilesContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tilesContainerView];
    
    // Create tiles.
    for (NSUInteger row = 0; row < MAX_ROWS; row ++) {
        for (NSUInteger column = 0; column < MAX_COLUMNS; column++) {
            Tile *tile = [self.tilesForRect getTileForRow:row column:column];
            if (!tile.hidden) {
                // Tile frame corresponds to location on display.
                
                // Border.
                CGRect borderFrame;
                borderFrame.size.width = roundf(self.tileWidth);
                borderFrame.size.height = roundf(self.tileHeight);
                borderFrame.origin.x = roundf(column * self.tileWidth);
                borderFrame.origin.y = roundf(row * self.tileHeight);
                UIView *borderView = [[UIView alloc] initWithFrame:borderFrame];
                borderView.backgroundColor = [UIColor BORDER_COLOR];
                UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
                [borderView addGestureRecognizer:tapGestureRecognizer];
                [self.tilesContainerView addSubview:borderView];
                
                // Image within border.
                UIImageView *tileImageView = [[UIImageView alloc] initWithImage:self.sourceImage];                
                CGRect imageFrame;
                imageFrame.size.width = roundf(self.tileWidth - BORDER_THICKNESS * 2.0);
                imageFrame.size.height = roundf(self.tileHeight - BORDER_THICKNESS * 2.0);
                imageFrame.origin.x = BORDER_THICKNESS;
                imageFrame.origin.y = BORDER_THICKNESS;
                tileImageView.frame = imageFrame;
                
                // Tile content corresponds to row and column of tiles original location.
                CGRect cropRect;
                cropRect.size.width = roundf(self.tileWidth - BORDER_THICKNESS * 2.0);
                cropRect.size.height = roundf(self.tileHeight - BORDER_THICKNESS * 2.0);
                cropRect.origin.x = roundf(tile.originalColumn * self.tileWidth + BORDER_THICKNESS);
                cropRect.origin.y = roundf(tile.originalRow * self.tileHeight + BORDER_THICKNESS);
                CGImageRef imageRef = CGImageCreateWithImageInRect([self.sourceImage CGImage], cropRect);
                [tileImageView setImage:[UIImage imageWithCGImage:imageRef]];
                CGImageRelease(imageRef);
                
                [borderView addSubview:tileImageView];
            } else {
                NSLog(@"row:%u column:%u ignoring hidden tile:%@", row, column, tile);
            }
        }
    }
}

- (void)handleTapFrom:(UITapGestureRecognizer *)recognizer {
    NSLog(@"recognizer:%@", recognizer);
    
    // Deduce row and column from mid-point of view; a little cheezy, but should be safe.
    NSUInteger row = (recognizer.view.frame.origin.y + recognizer.view.frame.size.height / 2) / self.tileHeight;
    NSUInteger column = (recognizer.view.frame.origin.x + recognizer.view.frame.size.width / 2) / self.tileWidth;
    
    // Search left
    NSUInteger foundColumn;
    BOOL found = [self foundHiddenTileSearchingLeftFromRow:row column:column foundColumn:&foundColumn];
    if (found) {
        NSLog(@"foundColumn:%u", foundColumn);
        [recognizer.view removeFromSuperview];
    }
    

    
}

- (BOOL)foundHiddenTileSearchingLeftFromRow:(NSUInteger)row column:(NSUInteger)column foundColumn:(NSUInteger *)foundColumn {
    BOOL found = NO;
    for (NSInteger c = column; c >= 0; c--) {
        Tile *tile = [self.tilesForRect getTileForRow:row column:c];
        if (tile.hidden) {
            found = YES;
            break;
        }
    }
    return found;
}



@end
