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
#define ARC4RANDOM_MAX      0x100000000
static const CGFloat minimumXPosition = 100.f;
static const CGFloat maximumXPosition = 450.f;
static const CGFloat maximumYPosition = 30.f;
static const CGFloat minimumYPosition = 10.f;

- (void)didLoadFromCCB {
    //self.physicsBody.collisionType = @"tool";
    //self.physicsBody.collisionCategories = @[@"tool"];
    //self.physicsBody.collisionMask = @[@"hero", @"enemy"];
    self.physicsBody.sensor = YES;
}
- (void)setupRandomPosition {
    //@@@@@@@@@@@@@@@@@@@@@ shark can only appear in front
    // value between 0.f and 1.f
    CGFloat randomX = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat rangeX = maximumXPosition;
    CGFloat randomY = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat rangeY = maximumYPosition-minimumYPosition;
    self.position = ccp((randomX * rangeX), minimumYPosition+randomY*rangeY);
}

@end
