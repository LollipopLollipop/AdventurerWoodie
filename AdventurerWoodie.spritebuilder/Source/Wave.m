//
//  Wave.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 3/23/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Wave.h"
#import "GameMechanics.h"

@implementation Wave
- (void)didLoadFromCCB {
    self.zOrder = DrawingOrderRearWave;
    self.physicsBody.collisionType = @"wave";
    self.physicsBody.sensor = YES;
}
@end
