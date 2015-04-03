//
//  Weapon.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 4/3/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Weapon.h"

@implementation Weapon

- (void)didLoadFromCCB {
    self.visible = FALSE;
    self.physicsBody.collisionType = @"weapon";
    self.physicsBody.sensor = YES;
}

@end
