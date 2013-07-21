//
//  Tile.h
//  TilePuzzle
//
//  Created by Dan Ratcliff on 7/20/13.
//  Copyright (c) 2013 Untethered Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tile : NSObject

@property (nonatomic, assign, readonly) NSInteger originalRow;
@property (nonatomic, assign, readonly) NSInteger originalColumn;
@property (nonatomic, assign) NSInteger currentRow;
@property (nonatomic, assign) NSInteger currentColumn;
@property (nonatomic, assign) BOOL hidden;

- (id)initWithRow:(NSInteger)row column:(NSInteger)column;

@end
