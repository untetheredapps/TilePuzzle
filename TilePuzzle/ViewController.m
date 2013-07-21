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

#define MAX_ROWS 4
#define MAX_COLUMNS 4

#define BORDER_THICKNESS 1.0

#define BORDER_COLOR lightGrayColor

@interface ViewController ()

@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, strong) UIImageView *sourceImageView;
@property (nonatomic, strong) UIView *tilesContainerView;
@property (nonatomic, strong) UIView *tilesContainerBorderView;
@property (nonatomic, strong) TilesForRect *tilesForRect;
@property (nonatomic, strong) Tile *hiddenTile;
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
    for (NSInteger row = 0; row < MAX_ROWS; row ++) {
        for (NSInteger column = 0; column < MAX_COLUMNS; column++) {
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

                // Configure taps.
                UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
                [borderView addGestureRecognizer:tapGestureRecognizer];

                // Configure swipes.
                [self addSwipeGestureRecognizerDirection:UISwipeGestureRecognizerDirectionRight view:borderView];
                [self addSwipeGestureRecognizerDirection:UISwipeGestureRecognizerDirectionLeft view:borderView];
                [self addSwipeGestureRecognizerDirection:UISwipeGestureRecognizerDirectionDown view:borderView];
                [self addSwipeGestureRecognizerDirection:UISwipeGestureRecognizerDirectionUp view:borderView];

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
                NSLog(@"row:%d column:%d hidden tile:%@", row, column, tile);
                self.hiddenTile = tile;
            }
        }
    }
}

- (void)addSwipeGestureRecognizerDirection:(UISwipeGestureRecognizerDirection)direction view:(UIView *)view {
    UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    swipeGestureRecognizer.direction =  direction;
    [view addGestureRecognizer:swipeGestureRecognizer];
}

- (void)fromTileView:(UIView *)tileView toRow:(NSInteger *)row column:(NSInteger *)column {
    NSLog(@"tileView:%@", tileView);
    
    // Deduce row and column from mid-point of view; a little cheezy, but should be safe.
    *row = (tileView.frame.origin.y + tileView.frame.size.height / 2) / self.tileHeight;
    *column = (tileView.frame.origin.x + tileView.frame.size.width / 2) / self.tileWidth;
}

- (void)handleGestureForTapRow:(NSInteger)tapRow tapColumn:(NSInteger)tapColumn {
    NSLog(@"tapRow:%d tapColumn:%d", tapRow, tapColumn);
    
    BOOL tilesMoved = NO;
    if (tapRow == self.hiddenTile.currentRow) {
        if (tapColumn < self.hiddenTile.currentColumn) {
            [self moveTilesRightForRow:tapRow leftColumn:tapColumn rightColumn:self.hiddenTile.currentColumn];
        } else {
            [self moveTilesLeftForRow:tapRow leftColumn:self.hiddenTile.currentColumn rightColumn:tapColumn];
        }
        tilesMoved = YES;
    } else if (tapColumn == self.hiddenTile.currentColumn) {
        if (tapRow < self.hiddenTile.currentRow) {
            [self moveTilesDownForColumn:tapColumn topRow:tapRow bottomRow:self.hiddenTile.currentRow];
        } else {
            [self moveTilesUpForColumn:tapColumn topRow:self.hiddenTile.currentRow bottomRow:tapRow];
        }
        tilesMoved = YES;
    }

    if (tilesMoved) {
        // Hidden tile replaces the one just tapped.
        [self.tilesForRect setTile:self.hiddenTile forRow:tapRow column:tapColumn];
        [self refreshViewForModel];
    }    
}

- (void)handleGestureForSwipeDirection:(UISwipeGestureRecognizerDirection)direction startRow:(NSInteger)startRow startColumn:(NSInteger)startColumn {
    NSLog(@"direction:%d startRow:%d startColumn:%d", direction, startRow, startColumn);

    // If swipe makes sense ...
    BOOL moveTiles = NO;
    if (startRow == self.hiddenTile.currentRow) {
        if (startColumn < self.hiddenTile.currentColumn) {
            moveTiles = (direction == UISwipeGestureRecognizerDirectionRight);
        } else {
            moveTiles = (direction == UISwipeGestureRecognizerDirectionLeft);
        }
    } else if (startColumn == self.hiddenTile.currentColumn) {
        if (startRow < self.hiddenTile.currentRow) {
            moveTiles = (direction == UISwipeGestureRecognizerDirectionDown);
        } else {
            moveTiles = (direction == UISwipeGestureRecognizerDirectionUp);
        }
    }
    
    // ... handle it like a tap.
    if (moveTiles) {
        [self handleGestureForTapRow:startRow tapColumn:startColumn];
    }
}



#pragma mark - 

- (void)moveTilesRightForRow:(NSInteger)row leftColumn:(NSInteger)leftColumn rightColumn:(NSInteger)rightColumn {
    // Start from right-most column.
    for (NSInteger c = rightColumn - 1; c >= leftColumn; c--) {
        Tile *tile = [self.tilesForRect getTileForRow:row column:c];
        [self.tilesForRect setTile:tile forRow:row column:(c + 1)];
    }
}

- (void)moveTilesLeftForRow:(NSInteger)row leftColumn:(NSInteger)leftColumn rightColumn:(NSInteger)rightColumn {
    // Start from left-most column.
    for (NSInteger c = leftColumn + 1; c <= rightColumn; c++) {
        Tile *tile = [self.tilesForRect getTileForRow:row column:c];
        [self.tilesForRect setTile:tile forRow:row column:(c - 1)];
    }
}

- (void)moveTilesDownForColumn:(NSInteger)column topRow:(NSInteger)topRow bottomRow:(NSInteger)bottomRow {
    // Start from bottom-most row.
    for (NSInteger r = bottomRow - 1; r >= topRow; r--) {
        Tile *tile = [self.tilesForRect getTileForRow:r column:column];
        [self.tilesForRect setTile:tile forRow:(r + 1) column:column];
    }
}

- (void)moveTilesUpForColumn:(NSInteger)column topRow:(NSInteger)topRow bottomRow:(NSInteger)bottomRow {
    // Start from top-most row.
    for (NSInteger r = topRow + 1; r <= bottomRow; r++) {
        Tile *tile = [self.tilesForRect getTileForRow:r column:column];
        [self.tilesForRect setTile:tile forRow:(r - 1) column:column];
    }
}


#pragma mark -

- (void)handleTapFrom:(UITapGestureRecognizer *)recognizer {
    NSLog(@"recognizer:%@", recognizer);
    NSInteger row;
    NSInteger column;
    [self fromTileView:recognizer.view toRow:&row column:&column];
    [self handleGestureForTapRow:row tapColumn:column];
}

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"recognizer:%@", recognizer);
    NSInteger row;
    NSInteger column;
    [self fromTileView:recognizer.view toRow:&row column:&column];
    [self handleGestureForSwipeDirection:recognizer.direction startRow:row startColumn:column];
}




@end
