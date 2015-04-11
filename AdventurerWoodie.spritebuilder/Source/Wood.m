//
//  Wood.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 2/23/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Wood.h"
#import "GameMechanics.h"

@implementation Wood

- (void)didLoadFromCCB {
    self.zOrder = DrawingOrderTool;
    //self.physicsBody.collisionType = @"tool";
    //self.physicsBody.collisionCategories = @[@"tool"];
    //self.physicsBody.collisionMask = @[@"hero", @"enemy"];
    self.physicsBody.sensor = YES;
}

@end
