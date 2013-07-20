//
//  TilesForRect.h
//  TilePuzzle
//
//  Created by Dan Ratcliff on 7/20/13.
//  Copyright (c) 2013 Untethered Apps LLC. All rights reserved.
//

@class Tile;

@interface TilesForRect : NSObject

- (id)initWithTilesForMaxRows:(NSUInteger)maxRows maxColumns:(NSUInteger)maxColumns;

- (void)setTile:(Tile *)tile forRow:(NSUInteger)row column:(NSUInteger)column;
- (Tile *)getTileForRow:(NSUInteger)row column:(NSUInteger)column;
- (Tile *)getRandomTile;
- (void)randomizeTileLocations;

@end
