//
//  GameMechanics.h
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 3/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCNode.h"
#import "WoodieWalkRight.h"
#import "Wave.h"
#import "WaveLightBlue.h"


typedef NS_ENUM(NSInteger, DrawingOrder) {
    
    DrawingOrderRearWave,
    DrawingOrderHero,
    DrawingOrderWood,
    DrawingOrderObstacles,
    DrawingOrderFrontWave
};


@interface GameMechanics : CCNode <CCPhysicsCollisionDelegate>
{
    // define variables here;
    WoodieWalkRight*    character;
    Wave*               rearWave1;
    Wave*               rearWave2;
    WaveLightBlue*      frontWave1;
    WaveLightBlue*      frontWave2;
    CCPhysicsNode       *_physicsNode;
    CCNode              *_startStation;
    float               timeSinceObstacle;
}

-(void) initialize;
-(void) addObstacle;
-(void) showScore;

@end
