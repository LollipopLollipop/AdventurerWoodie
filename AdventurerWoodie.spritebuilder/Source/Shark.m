//
//  Shark.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 3/18/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Shark.h"
#import "GameMechanics.h"

@implementation Shark

#define ARC4RANDOM_MAX      0x100000000

static const CGFloat minimumXPosition = 100.f;

static const CGFloat maximumXPosition = 450.f;

- (void)didLoadFromCCB {
    //self.physicsBody.collisionType = @"enemy";
    //self.physicsBody.collisionCategories = @[@"enemy"];
    //self.physicsBody.collisionMask = @[@"weapon"];
    
    self.physicsBody.sensor = YES;
}

- (void)setupRandomPosition {
    //@@@@@@@@@@@@@@@@@@@@@ shark can only appear in front
    // value between 0.f and 1.f
    CGFloat random = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat range = maximumXPosition - self.position.x;
    self.position = ccp(self.position.x + (random * range), self.position.y);
}

@end
