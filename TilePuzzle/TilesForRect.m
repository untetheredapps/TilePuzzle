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

- (id)initWithTilesForMaxRows:(NSUInteger)maxRows maxColumns:(NSUInteger)maxColumns {
    if ((self = [super init])) {
        for (NSUInteger row = 0; row < maxRows; row++) {
            for (NSUInteger column = 0; column < maxColumns; column++) {
                Tile *tile = [[Tile alloc] initWithRow:row column:column];
                [self setTile:tile forRow:row column:column];
            }
        }
    }
    
    return self;
}

#pragma mark - Public methods

- (void)setTile:(Tile *)tile forRow:(NSUInteger)row column:(NSUInteger)column {
    [self.tilesDictionary setObject:tile forKey:[[self class] keyForRow:row column:column]];
    tile.currentRow = row;
    tile.currentColumn = column;
}

- (Tile *)getTileForRow:(NSUInteger)row column:(NSUInteger)column {
    return [self.tilesDictionary objectForKey:[[self class] keyForRow:row column:column]];
}

- (Tile *)getRandomTile {
    NSArray *tilesArray = [self.tilesDictionary allValues];
    NSUInteger count = tilesArray.count;
    NSUInteger randomIndex = arc4random() % count;
    Tile *randomIndexTile = [tilesArray objectAtIndex:randomIndex];
    return randomIndexTile;
}

- (void)randomizeTileLocations {
    NSArray *tilesArray = [self.tilesDictionary allValues];
    NSUInteger count = tilesArray.count;
    for (NSUInteger i = 0; i < count; i++) {
        NSUInteger randomIndex = arc4random() % count;
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

+ (NSArray *)keyForRow:(NSUInteger)row column:(NSUInteger)column {
    return [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:row], [NSNumber numberWithUnsignedInteger:column], nil];
}

- (void)swapCurrentLocationOfTile:(Tile *)aTile withOtherTile:(Tile *)otherTile {
    if (aTile != otherTile) {
        NSUInteger swapSaveRow = aTile.currentRow;
        NSUInteger swapSaveColumn = aTile.currentColumn;
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
