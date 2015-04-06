//
//  WaveLightBlue.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 3/23/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "WaveLightBlue.h"
#import "GameMechanics.h"

@implementation WaveLightBlue

- (void)didLoadFromCCB {
    self.zOrder = DrawingOrderFrontGround;
    self.physicsBody.collisionType = @"ground";
    self.physicsBody.sensor = YES;
}
@end
