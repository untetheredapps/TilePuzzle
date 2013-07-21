//
//  Tile.m
//  TilePuzzle
//
//  Created by Dan Ratcliff on 7/20/13.
//  Copyright (c) 2013 Untethered Apps LLC. All rights reserved.
//

#import "Tile.h"

@interface Tile ()
@property (nonatomic, assign) NSInteger originalRow;
@property (nonatomic, assign) NSInteger originalColumn;
@end

@implementation Tile

- (id)initWithRow:(NSInteger)row column:(NSInteger)column {
    if ((self = [super init])) {
        self.currentRow = self.originalRow = row;
        self.currentColumn = self.originalColumn = column;
    }
    return self;
}

// Overridden.
- (NSString *)description {
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"<%@: %p>", [self class], self];
    [s appendString:@", "];
    [s appendFormat:@"originalRow:%u", self.originalRow];
    [s appendString:@", "];
    [s appendFormat:@"originalColumn:%u", self.originalColumn];
    [s appendString:@", "];
    [s appendFormat:@"currentRow:%u", self.currentRow];
    [s appendString:@", "];
    [s appendFormat:@"currentColumn:%u", self.currentColumn];
    [s appendString:@", "];
    [s appendFormat:@"hidden:%u", self.hidden];
    return [NSString stringWithString:s];
}

@end
