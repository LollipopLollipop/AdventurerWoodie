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
    DrawingOrderObstacles,
    DrawingOrderWood,
    DrawingOrderFrontWave
};


@interface GameMechanics : CCNode <CCPhysicsCollisionDelegate>
{
    // define variables here;
    WoodieWalkRight*    _character;
    Wave*               _rearWave1;
    Wave*               _rearWave2;
    WaveLightBlue*      _frontWave1;
    WaveLightBlue*      _frontWave2;
    CCPhysicsNode       *_physicsNode;
    CCPhysicsNode       *_staticPhyNode;
    CCNode              *_startStation;
    CCNode              *_pullbackNode;
    CCNode              *_bottomPullBack;
    float               _timeSinceObstacle;
    CCNode              *_mouseJointNode;
    CCPhysicsJoint      *_mouseJoint;
    CCNode              *_readyWood;
}

-(void) initialize;
-(void) addObstacle;
- (void)placeWood:(CGPoint)touchLocation;
-(void) showScore;

@end
