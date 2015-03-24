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
    self.zOrder = DrawingOrderFrontWave;
    //self.physicsBody.collisionType = @"level";
    self.physicsBody.sensor = YES;
}
@end
