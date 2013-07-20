//
//  Tile.h
//  TilePuzzle
//
//  Created by Dan Ratcliff on 7/20/13.
//  Copyright (c) 2013 Untethered Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tile : NSObject

@property (nonatomic, assign, readonly) NSUInteger originalRow;
@property (nonatomic, assign, readonly) NSUInteger originalColumn;
@property (nonatomic, assign) NSUInteger currentRow;
@property (nonatomic, assign) NSUInteger currentColumn;
@property (nonatomic, assign) BOOL hidden;

- (id)initWithRow:(NSUInteger)row column:(NSUInteger)column;

@end
