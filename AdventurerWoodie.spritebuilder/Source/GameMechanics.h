//
//  GameMechanics.h
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 3/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCNode.h"
#import "WoodieWalkRight.h"
typedef NS_ENUM(NSInteger, DrawingOrder) {
    DrawingOrderPipes,
    DrawingOrderGround,
    DrawingOrderHero
};


@interface GameMechanics : CCNode <CCPhysicsCollisionDelegate>
{
    // define variables here;
    WoodieWalkRight*    character;
    CCPhysicsNode       *_physicsNode;
    CCPhysicsNode       *_woodContainer;
    CCNode              *_startStation;
    float               timeSinceObstacle;
}

-(void) initialize;
-(void) addObstacle;
-(void) showScore;

@end
