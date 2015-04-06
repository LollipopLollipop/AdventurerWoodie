//
//  WoodieWalkRight.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 2/23/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "WoodieWalkRight.h"
#import "GameMechanics.h"


@implementation WoodieWalkRight
- (void)didLoadFromCCB
{
    //self.scaleX = 0.2f;
    //self.scaleY = 0.2f;
    self.zOrder = DrawingOrderHero;
    self.physicsBody.collisionType = @"hero";
    //self.physicsBody.sensor = YES; //hero starts falling after turnning on
}


@end
