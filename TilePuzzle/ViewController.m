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

#define IMAGE_NAME @"globe.jpg"

#define BORDER_THICKNESS 1.0

#define VIEW_MARGIN 10.0

#define BORDER_COLOR lightGrayColor

#define EPSILON 1.0

#define TILE_VIEW_ARRAY_INDEX_TILE 0
#define TILE_VIEW_ARRAY_INDEX_VIEW 1

@interface ViewController ()

@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, assign) CGRect sourceImageViewFrame;
@property (nonatomic, strong) UIView *tilesContainerView;
@property (nonatomic, strong) TilesForRect *tilesForRect;
@property (nonatomic, strong) Tile *hiddenTile;
@property (nonatomic, assign) CGFloat tileWidth;
@property (nonatomic, assign) CGFloat tileHeight;
@property (nonatomic, strong) UIView *tappedView;
@property (nonatomic, strong) UIView *pannedView;
@property (nonatomic, assign) NSInteger slideStartRow;
@property (nonatomic, assign) NSInteger slideStartColumn;
@property (nonatomic, assign) NSInteger slideStopRow;
@property (nonatomic, assign) NSInteger slideStopColumn;
@property (nonatomic, strong) NSArray *tilesViewsToSlideArray;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Set the background to a top-light gray to bottom-dark gray gradient.
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = self.view.bounds;
    UIColor *topLightGrayColor = [UIColor colorWithRed:125/255.0 green:125/255.0 blue:125/255.0 alpha:1];
    UIColor *bottomDarkGrayColor = [UIColor colorWithRed:33/255.0 green:33/255.0 blue:33/255.0 alpha:1];
    self.gradientLayer.colors = [NSArray arrayWithObjects:(id)topLightGrayColor.CGColor, (id)bottomDarkGrayColor.CGColor, nil];
    [self.view.layer addSublayer:self.gradientLayer];
    
    // TODO: Find a better solution that tracks view frame automatically.
    // Make transitions less noticeable by choosing a color used by the gradient.
    self.view.backgroundColor = bottomDarkGrayColor;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    self.gradientLayer.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    // Establish the source image and geometry.
    UIImageView *sourceImageView = [[UIImageView alloc] initWithImage:self.sourceImage];
    sourceImageView.center = CGPointMake(roundf(self.view.bounds.size.width / 2), roundf(self.view.bounds.size.height / 2));
    self.sourceImageViewFrame = sourceImageView.frame;
    self.tileWidth = sourceImageView.bounds.size.width / MAX_COLUMNS;
    self.tileHeight = sourceImageView.bounds.size.height / MAX_ROWS;
    
    [self initModelForNewGame];
    [self refreshViewForModel];
}

- (void)viewDidAppear:(BOOL)animated {
    self.gradientLayer.frame = self.view.bounds;   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private methods

// Lazy getter.
- (UIImage *)sourceImage {
    if (!_sourceImage) {
        // If everything fits in all rotations, we will use the full size image.  Otherwise, we will resize once for the device.
        _sourceImage = [UIImage imageNamed:IMAGE_NAME];
        
        CGSize imageSize = _sourceImage.size;
        CGSize viewSize = self.view.bounds.size;
        CGFloat margin = [UIApplication sharedApplication].statusBarFrame.size.height + VIEW_MARGIN;
        
        // Max dimension is the minimum of image dimension and both view dimensions.
        CGFloat maxWidth = fminf(imageSize.width, viewSize.width - BORDER_THICKNESS * 2.0 - margin);
        maxWidth = fminf(maxWidth, viewSize.height - BORDER_THICKNESS * 2.0);
        
        CGFloat maxHeight = fminf(imageSize.width, viewSize.width - BORDER_THICKNESS * 2.0 - margin);
        maxHeight = fminf(maxHeight, viewSize.height - BORDER_THICKNESS * 2.0);
       
        CGFloat widthRatio = 1.0;
        if (maxWidth < imageSize.width) {
            widthRatio = maxWidth / imageSize.width;
        }
        
        CGFloat heightRatio = 1.0;
        if (maxHeight < imageSize.height) {
            heightRatio = maxHeight / imageSize.height;
        }
        
        if (widthRatio != 1.0 || heightRatio != 1.0) {
            CGFloat minRatio = fminf(widthRatio, heightRatio);
            CGFloat width = imageSize.width * minRatio;
            CGFloat height = imageSize.height * minRatio;
            
            UIGraphicsBeginImageContext(CGSizeMake(width, height));
            UIGraphicsGetCurrentContext();
            [_sourceImage drawInRect: CGRectMake(0, 0, width, height)];
            UIImage *reducedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            _sourceImage = reducedImage;
        }
    }
    
    return _sourceImage;
}


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
    self.tilesContainerView = [[UIView alloc] initWithFrame:self.sourceImageViewFrame];
    self.tilesContainerView.backgroundColor = [UIColor clearColor];

    // Keep it centered.
    self.tilesContainerView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                                UIViewAutoresizingFlexibleBottomMargin |
                                                UIViewAutoresizingFlexibleLeftMargin |
                                                UIViewAutoresizingFlexibleRightMargin);
    
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

- (void)finishSlidingTilesFromStartRow:(NSInteger)startRow startColumn:(NSInteger)startColumn withCompletion:(void (^)(void))completionBlock {
    NSLog(@"startRow:%d startColumn:%d", startRow, startColumn);
    // Update model.
    if (startRow == self.hiddenTile.currentRow) {
        if (startColumn < self.hiddenTile.currentColumn) {
            [self moveTilesRightForRow:startRow leftColumn:startColumn rightColumn:self.hiddenTile.currentColumn];
        } else {
            [self moveTilesLeftForRow:startRow leftColumn:self.hiddenTile.currentColumn rightColumn:startColumn];
        }
    } else if (startColumn == self.hiddenTile.currentColumn) {
        if (startRow < self.hiddenTile.currentRow) {
            [self moveTilesDownForColumn:startColumn topRow:startRow bottomRow:self.hiddenTile.currentRow];
        } else {
            [self moveTilesUpForColumn:startColumn topRow:self.hiddenTile.currentRow bottomRow:startRow];
        }
    }
    // Hidden tile replaces the one just tapped.
    [self.tilesForRect setTile:self.hiddenTile forRow:startRow column:startColumn];
    
    [self animateSlidingTilesWithCompletion:completionBlock];
}

- (void)animateSlidingTilesWithCompletion:(void (^)(void))completionBlock {
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // Update sliding views to match the new model.
                         for (NSArray *tileViewArray in self.tilesViewsToSlideArray) {
                             Tile *tile = [tileViewArray objectAtIndex:TILE_VIEW_ARRAY_INDEX_TILE];
                             UIView *subview = [tileViewArray objectAtIndex:TILE_VIEW_ARRAY_INDEX_VIEW];
                             
                             CGRect newBorderFrame = subview.frame;
                             newBorderFrame.origin.x = roundf(tile.currentColumn * self.tileWidth);
                             newBorderFrame.origin.y = roundf(tile.currentRow * self.tileHeight);
                             subview.frame = newBorderFrame;
                         }
                     }
                     completion:^(BOOL finished){
                         NSLog(@"Done animating.");
                         self.tilesViewsToSlideArray = nil;
                         if (completionBlock) {
                             completionBlock();
                         }
                     }];
}


- (void)handleTapFrom:(UITapGestureRecognizer *)tapGestureRecognizer {
    NSLog(@"tapGestureRecognizer:%@", tapGestureRecognizer);
    
    if (self.tappedView || self.pannedView) {
        NSLog(@"Tap already in progress.");
    } else {
        // Establish and save start location.
        NSInteger startRow;
        NSInteger startColumn;
        [self convertFromTileView:tapGestureRecognizer.view toRow:&startRow column:&startColumn];
        
        if (startRow == self.hiddenTile.currentRow || startColumn == self.hiddenTile.currentColumn) {
            self.tappedView = tapGestureRecognizer.view;
            [self establishSlideStartStopTilesViewsFromStartRow:startRow startColumn:startColumn];
            for (NSArray *tileViewArray in self.tilesViewsToSlideArray) {
                UIView *subview = [tileViewArray objectAtIndex:TILE_VIEW_ARRAY_INDEX_VIEW];
                [tapGestureRecognizer.view.superview bringSubviewToFront:subview];
            }
            [self finishSlidingTilesFromStartRow:startRow startColumn:startColumn withCompletion:^{
                self.tappedView = nil;
            }];
        }
    }
}


- (void)handlePanFrom:(UIPanGestureRecognizer *)panGestureRecognizer {
    NSLog(@"panGestureRecognizer:%@", panGestureRecognizer);
    
    if (self.tappedView) {
        NSLog(@"Tap already in progress.");
    } else {
        if (self.pannedView) {
            NSLog(@"Pan already in progress.");
        } else {
            if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
                // Establish and save start location.
                NSInteger startRow;
                NSInteger startColumn;
                [self convertFromTileView:panGestureRecognizer.view toRow:&startRow column:&startColumn];
                
                if (startRow == self.hiddenTile.currentRow || startColumn == self.hiddenTile.currentColumn) {
                    self.pannedView = panGestureRecognizer.view;
                    [self establishSlideStartStopTilesViewsFromStartRow:startRow startColumn:startColumn];
                    for (NSArray *tileViewArray in self.tilesViewsToSlideArray) {
                        UIView *subview = [tileViewArray objectAtIndex:TILE_VIEW_ARRAY_INDEX_VIEW];
                        [panGestureRecognizer.view.superview bringSubviewToFront:subview];
                    }
                }
            }
        }
        
        if (self.pannedView && self.pannedView == panGestureRecognizer.view) {
            // Find boundary where we allow movement.
            CGPoint oldCenter = panGestureRecognizer.view.center;
            CGPoint newCenter = [panGestureRecognizer locationInView:panGestureRecognizer.view.superview];
            CGPoint startCenter = [self centerOfViewFromRow:self.slideStartRow column:self.slideStartColumn];
            CGPoint stopCenter = [self centerOfViewFromRow:self.slideStopRow column:self.slideStopColumn];
            
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
            
            for (NSArray *tileViewArray in self.tilesViewsToSlideArray) {
                UIView *subview = [tileViewArray objectAtIndex:TILE_VIEW_ARRAY_INDEX_VIEW];
                CGPoint newSubviewCenter = subview.center;
                newSubviewCenter.x += distanceToMoveX;
                newSubviewCenter.y += distanceToMoveY;
                subview.center = newSubviewCenter;
            }
            
            // TODO: Confirm whether we need to handle UIGestureRecognizerStateCancelled and UIGestureRecognizerStateFailed.
            if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
                CGFloat distanceStartStopX = fabsf(startCenter.x - stopCenter.x);
                CGFloat distanceStartStopY = fabsf(startCenter.y - stopCenter.y);
                
                BOOL isMovingToNewLocation = NO;
                if (distanceStartStopX > distanceStartStopY) {
                    // Horizontal pan.
                    CGFloat distanceFromStartX = fabsf(startCenter.x - newCenter.x);
                    if (distanceFromStartX > distanceStartStopX / 2.0) {
                        isMovingToNewLocation = YES;
                    }
                } else {
                    // Vertical pan.
                    CGFloat distanceFromStartY = fabsf(startCenter.y - newCenter.y);
                    if (distanceFromStartY > distanceStartStopY / 2.0) {
                        isMovingToNewLocation = YES;
                    }
                }
                
                if (isMovingToNewLocation) {
                    [self finishSlidingTilesFromStartRow:self.slideStartRow startColumn:self.slideStartColumn withCompletion:^{
                        self.pannedView = nil;
                    }];
                } else {
                    [self animateSlidingTilesWithCompletion:^{
                        self.pannedView = nil;
                    }];
                }
            }
        }
    }
}


#pragma mark -

- (void)establishSlideStartStopTilesViewsFromStartRow:(NSInteger)startRow startColumn:(NSInteger)startColumn {
    self.slideStartRow = startRow;
    self.slideStartColumn = startColumn;
    
    // Determine and save stop location.
    NSInteger stopRow;
    NSInteger stopColumn;
    [self determineFromStartRow:startRow startColumn:startColumn toStopRow:&stopRow stopColumn:&stopColumn];
    self.slideStopRow = stopRow;
    self.slideStopColumn = stopColumn;
    
    if (startRow == stopRow) {
        self.tilesViewsToSlideArray = [self tilesViewsToSlideArrayInRow:startRow aColumn:startColumn];
    } else if (startColumn == stopColumn) {
        self.tilesViewsToSlideArray = [self tilesViewsToSlideArrayInColumn:startColumn aRow:startRow];
    } else {
        NSAssert(NO, @"Yikes!");
    }
}



#pragma mark -

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


#pragma mark -

- (NSArray *)tilesViewsToSlideArrayInRow:(NSInteger)row aColumn:(NSInteger)aColumn {
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
                [mutableArray addObject:[NSArray arrayWithObjects:tile, tileView, nil]];
            } else {
                NSAssert(NO, @"Yikes!");
            }
        }
    }
    
    return [NSArray arrayWithArray:mutableArray];
}

- (NSArray *)tilesViewsToSlideArrayInColumn:(NSInteger)column aRow:(NSInteger)aRow {
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
                [mutableArray addObject:[NSArray arrayWithObjects:tile, tileView, nil]];
            } else {
                NSAssert(NO, @"Yikes!");
            }
        }
    }
    
    return [NSArray arrayWithArray:mutableArray];
}


#pragma mark -

- (CGPoint)centerOfViewFromRow:(NSInteger)row column:(NSInteger)column {
    CGPoint center;
    center.x = roundf(column * self.tileWidth + self.tileWidth / 2.0);
    center.y = roundf(row * self.tileHeight + self.tileHeight / 2.0);
    return center;
}

@end
