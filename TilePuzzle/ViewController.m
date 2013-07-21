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

#define EPSILON 1.0f

@interface ViewController ()

@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, strong) UIImageView *sourceImageView;
@property (nonatomic, strong) UIView *tilesContainerView;
@property (nonatomic, strong) UIView *tilesContainerBorderView;
@property (nonatomic, strong) TilesForRect *tilesForRect;
@property (nonatomic, strong) Tile *hiddenTile;
@property (nonatomic, assign) CGFloat tileWidth;
@property (nonatomic, assign) CGFloat tileHeight;
@property (nonatomic, assign) BOOL isPanning;
@property (nonatomic, assign) NSInteger panStartRow;
@property (nonatomic, assign) NSInteger panStartColumn;
@property (nonatomic, assign) NSInteger panStopRow;
@property (nonatomic, assign) NSInteger panStopColumn;
@property (nonatomic, strong) NSArray *viewsToPanArray;

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

                // Configure dragging.
                UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
                panGestureRecognizer.maximumNumberOfTouches = 1;
                [borderView addGestureRecognizer:panGestureRecognizer];
                
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

- (void)convertFromTileView:(UIView *)tileView toRow:(NSInteger *)row column:(NSInteger *)column {
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

- (void)determineFromStartRow:(NSInteger)startRow startColumn:(NSInteger)startColumn toStopRow:(NSInteger *)stopRow stopColumn:(NSInteger *)stopColumn {
    NSLog(@"startRow:%d startColumn:%d", startRow, startColumn);
    
    *stopRow = startRow;
    *stopColumn = startColumn;
    if (startRow == self.hiddenTile.currentRow) {
        if (startColumn < self.hiddenTile.currentColumn) {
            *stopColumn = startColumn + 1;
        } else {
            *stopColumn = startColumn - 1;
        }
    } else if (startColumn == self.hiddenTile.currentColumn) {
        if (startRow < self.hiddenTile.currentRow) {
            *stopRow = startRow + 1;
        } else {
            *stopRow = startRow - 1;
        }
    }

    NSLog(@"*stopRow:%d *stopColumn:%d", *stopRow, *stopColumn);
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

- (void)handleTapFrom:(UITapGestureRecognizer *)tapGestureRecognizer {
    NSLog(@"tapGestureRecognizer:%@", tapGestureRecognizer);
    NSInteger row;
    NSInteger column;
    [self convertFromTileView:tapGestureRecognizer.view toRow:&row column:&column];
    [self handleGestureForTapRow:row tapColumn:column];
}

- (UIView *)tileViewForRow:(NSInteger)row column:(NSInteger)column {
    UIView *tileView = nil;
    
    CGPoint center = [self centerOfViewFromRow:row column:column];
    
    for (UIView *view in self.tilesContainerView.subviews) {
        CGFloat distanceX = fabsf(center.x - view.center.x);
        CGFloat distanceY = fabsf(center.y - view.center.y);
        if (distanceX < EPSILON && distanceY < EPSILON) {
            tileView = view;
            break;
        }
    }
    
    return tileView;
}

- (NSArray *)viewsInRow:(NSInteger)row aColumn:(NSInteger)aColumn {
    NSLog(@"aColumn:%d", aColumn);
    NSMutableArray *mutableArray = [NSMutableArray array];
    
    NSInteger startColumn = MIN(aColumn, self.hiddenTile.currentColumn);
    NSInteger endColumn = MAX(aColumn, self.hiddenTile.currentColumn);
    
    for (NSInteger c = startColumn; c <= endColumn; c++) {
        Tile *tile = [self.tilesForRect getTileForRow:row column:c];
        if (tile && !tile.hidden) {
            // There was a tile at the location; find associated view.
            UIView *tileView = [self tileViewForRow:row column:c];
            if (tileView) {
                [mutableArray addObject:tileView];
            } else {
                NSAssert(NO, @"Yikes!");
            }
        }
    }
    
    return [NSArray arrayWithArray:mutableArray];
}

- (NSArray *)viewsInColumn:(NSInteger)column aRow:(NSInteger)aRow {
    NSLog(@"aRow:%d", aRow);
    NSMutableArray *mutableArray = [NSMutableArray array];
    
    NSInteger startRow = MIN(aRow, self.hiddenTile.currentRow);
    NSInteger endRow = MAX(aRow, self.hiddenTile.currentRow);
    
    for (NSInteger r = startRow; r <= endRow; r++) {
        Tile *tile = [self.tilesForRect getTileForRow:r column:column];
        if (tile && !tile.hidden) {
            // There was a tile at the location; find associated view.
            UIView *tileView = [self tileViewForRow:r column:column];
            if (tileView) {
                [mutableArray addObject:tileView];
            } else {
                NSAssert(NO, @"Yikes!");
            }
        }
    }
    
    return [NSArray arrayWithArray:mutableArray];
}


- (void)handlePanFrom:(UIPanGestureRecognizer *)panGestureRecognizer {
    NSLog(@"panGestureRecognizer:%@", panGestureRecognizer);

    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // Establish and save start location.
        NSInteger startRow;
        NSInteger startColumn;
        [self convertFromTileView:panGestureRecognizer.view toRow:&startRow column:&startColumn];
        
        self.isPanning = (startRow == self.hiddenTile.currentRow || startColumn == self.hiddenTile.currentColumn);
        if (self.isPanning) {
            self.panStartRow = startRow;
            self.panStartColumn = startColumn;
            
            // Determine and save stop location.
            NSInteger stopRow;
            NSInteger stopColumn;
            [self determineFromStartRow:startRow startColumn:startColumn toStopRow:&stopRow stopColumn:&stopColumn];
            self.panStopRow = stopRow;
            self.panStopColumn = stopColumn;
            
            if (startRow == stopRow) {
                self.viewsToPanArray = [self viewsInRow:startRow aColumn:startColumn];
            } else if (startColumn == stopColumn) {
                self.viewsToPanArray = [self viewsInColumn:startColumn aRow:startRow];
            } else {
                NSAssert(NO, @"Yikes!");
            }
            
            for (UIView *subview in self.viewsToPanArray) {
                [panGestureRecognizer.view.superview bringSubviewToFront:subview];
            }
        }
    }
    
    if (self.isPanning) {
        // Every time.
        
        // Find boundary where we allow movement.
        CGPoint oldCenter = panGestureRecognizer.view.center;
        CGPoint newCenter = [panGestureRecognizer locationInView:panGestureRecognizer.view.superview];
        CGPoint startCenter = [self centerOfViewFromRow:self.panStartRow column:self.panStartColumn];
        CGPoint stopCenter = [self centerOfViewFromRow:self.panStopRow column:self.panStopColumn];
        
        // Bound view center to rectangle (actually a vertical or horizontal line) bounded by startCenter and stopCenter.
        CGFloat minX = fminf(startCenter.x, stopCenter.x);
        CGFloat maxX = fmaxf(startCenter.x, stopCenter.x);
        CGFloat minY = fminf(startCenter.y, stopCenter.y);
        CGFloat maxY = fmaxf(startCenter.y, stopCenter.y);
        newCenter.x = fmaxf(newCenter.x, minX);
        newCenter.x = fminf(newCenter.x, maxX);
        newCenter.y = fmaxf(newCenter.y, minY);
        newCenter.y = fminf(newCenter.y, maxY);
        
        CGFloat distanceToMoveX = newCenter.x - oldCenter.x;
        CGFloat distanceToMoveY = newCenter.y - oldCenter.y;
        
        for (UIView *subview in self.viewsToPanArray) {
            CGPoint newSubviewCenter = subview.center;
            newSubviewCenter.x += distanceToMoveX;
            newSubviewCenter.y += distanceToMoveY;
            subview.center = newSubviewCenter;
        }
        
        if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
            CGFloat distanceStartStopX = fabsf(startCenter.x - stopCenter.x);
            CGFloat distanceStartStopY = fabsf(startCenter.y - stopCenter.y);
            
            if (distanceStartStopX > distanceStartStopY) {
                // Horizontal pan.
                CGFloat distanceFromStartX = fabsf(startCenter.x - newCenter.x);
                if (distanceFromStartX > distanceStartStopX / 2.0) {
                    [self handleGestureForTapRow:self.panStartRow tapColumn:self.panStartColumn];
                } else {
                    [self refreshViewForModel];
                }
            } else {
                // Vertical pan.
                CGFloat distanceFromStartY = fabsf(startCenter.y - newCenter.y);
                if (distanceFromStartY > distanceStartStopY / 2.0) {
                    [self handleGestureForTapRow:self.panStartRow tapColumn:self.panStartColumn];
                } else {
                    [self refreshViewForModel];
                }
            }
            self.isPanning = NO;
        }
    }
}

- (CGPoint)centerOfViewFromRow:(NSInteger)row column:(NSInteger)column {
    CGPoint center;
    center.x = roundf(column * self.tileWidth + self.tileWidth / 2.0);
    center.y = roundf(row * self.tileHeight + self.tileHeight / 2.0);
    return center;
}

@end
