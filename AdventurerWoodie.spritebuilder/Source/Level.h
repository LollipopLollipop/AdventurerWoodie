//
//  Level.h
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 4/6/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface Level : CCNode

@property (nonatomic, copy) NSString *nextLevelName;
@property (nonatomic, assign) int levelSpeed;

@end
