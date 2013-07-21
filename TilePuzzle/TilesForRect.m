//
//  TilesForRect.m
//  TilePuzzle
//
//  Created by Dan Ratcliff on 7/20/13.
//  Copyright (c) 2013 Untethered Apps LLC. All rights reserved.
//

#import "TilesForRect.h"
#import "Tile.h"

@interface TilesForRect ()

@property (nonatomic, strong) NSMutableDictionary *tilesDictionary;

@end

@implementation TilesForRect

- (id)initWithTilesForMaxRows:(NSInteger)maxRows maxColumns:(NSInteger)maxColumns {
    if ((self = [super init])) {
        for (NSInteger row = 0; row < maxRows; row++) {
            for (NSInteger column = 0; column < maxColumns; column++) {
                Tile *tile = [[Tile alloc] initWithRow:row column:column];
                [self setTile:tile forRow:row column:column];
            }
        }
    }
    
    return self;
}

#pragma mark - Public methods

- (void)setTile:(Tile *)tile forRow:(NSInteger)row column:(NSInteger)column {
    [self.tilesDictionary setObject:tile forKey:[[self class] keyForRow:row column:column]];
    tile.currentRow = row;
    tile.currentColumn = column;
}

- (Tile *)getTileForRow:(NSInteger)row column:(NSInteger)column {
    return [self.tilesDictionary objectForKey:[[self class] keyForRow:row column:column]];
}

- (Tile *)getRandomTile {
    NSArray *tilesArray = [self.tilesDictionary allValues];
    NSInteger count = tilesArray.count;
    NSInteger randomIndex = arc4random() % count;
    Tile *randomIndexTile = [tilesArray objectAtIndex:randomIndex];
    return randomIndexTile;
}

// TODO: Replace with an approach that guarantees solvability.
// "A single swap of the tiles 14 and 15 is an odd permutation and hence not possible."  http://www.jaapsch.net/puzzles/fifteen.htm
- (void)randomizeTileLocations {
    NSArray *tilesArray = [self.tilesDictionary allValues];
    NSInteger count = tilesArray.count;
    for (NSInteger i = 0; i < count; i++) {
        NSInteger randomIndex = arc4random() % count;
        Tile *iTile = [tilesArray objectAtIndex:i];
        Tile *randomIndexTile = [tilesArray objectAtIndex:randomIndex];
        [self swapCurrentLocationOfTile:iTile withOtherTile:randomIndexTile];
    }
}

// Overridden.
- (NSString *)description {
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"<%@: %p>", [self class], self];
    for (NSObject *key in [self sortedKeysForTitlesDictionary]) {
        NSObject *object = [self.tilesDictionary objectForKey:key];
        [s appendFormat:@"\nkey:%@ object:%@", key, object];
    }
    return [NSString stringWithString:s];
}

#pragma mark - Private methods

+ (NSArray *)keyForRow:(NSInteger)row column:(NSInteger)column {
    return [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:row], [NSNumber numberWithUnsignedInteger:column], nil];
}

- (void)swapCurrentLocationOfTile:(Tile *)aTile withOtherTile:(Tile *)otherTile {
    if (aTile != otherTile) {
        NSInteger swapSaveRow = aTile.currentRow;
        NSInteger swapSaveColumn = aTile.currentColumn;
        [self setTile:aTile forRow:otherTile.currentRow column:otherTile.currentColumn];
        [self setTile:otherTile forRow:swapSaveRow column:swapSaveColumn];
    }
}

- (NSArray *)sortedKeysForTitlesDictionary {
    NSArray *keys = [self.tilesDictionary allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(NSArray *aArray, NSArray *bArray) {
        NSNumber *aRowNumber = [aArray objectAtIndex:0];
        NSNumber *bRowNumber = [bArray objectAtIndex:0];
        NSComparisonResult rowComparisonResult = [aRowNumber compare:bRowNumber];
        if (rowComparisonResult == NSOrderedSame) {
            NSNumber *aColumnNumber = [aArray objectAtIndex:1];
            NSNumber *bColumnNumber = [bArray objectAtIndex:1];
            return [aColumnNumber compare:bColumnNumber];
        } else {
            return rowComparisonResult;
        }
    }];
    return sortedKeys;
}

// Lazy getter.
- (NSMutableDictionary *)tilesDictionary {
    if (!_tilesDictionary) {
        _tilesDictionary = [NSMutableDictionary dictionary];
    }
    return _tilesDictionary;
}

@end
