//
//  TilesForRect.h
//  TilePuzzle
//
//  Created by Dan Ratcliff on 7/20/13.
//  Copyright (c) 2013 Untethered Apps LLC. All rights reserved.
//

@class Tile;

@interface TilesForRect : NSObject

- (id)initWithTilesForMaxRows:(NSInteger)maxRows maxColumns:(NSInteger)maxColumns;

- (void)setTile:(Tile *)tile forRow:(NSInteger)row column:(NSInteger)column;
- (Tile *)getTileForRow:(NSInteger)row column:(NSInteger)column;
- (Tile *)getRandomTile;
- (void)randomizeTileLocations;

@end
