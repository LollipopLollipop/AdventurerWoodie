//
//  Level1.h
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 4/4/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCNode.h"
#import "GameMechanics.h"

@interface Level1 : GameMechanics
{
    //variable used for parallax
    CGPoint             _cloudParallaxRatio;
    CCNode              *_parallaxContainer;
    CCParallaxNode      *_parallaxBackground;
    //variable representing different scene component
    WoodieWalkRight*    _character;
    CCPhysicsNode       *_physicsNode;
    CCPhysicsNode       *_staticPhyNode;
    CCNode              *_startStation;
    CCNode              *_pullbackNode;
    CCNode              *_bottomPullBack;
    CCNode              *_weaponPullbackNode;
    CCNode              *_weaponBottomPullBack;
    CCNode              *_mouseJointNode;
    CCPhysicsJoint      *_mouseJoint;
    CCNode              *_readyWood;
    CCNode              *_weapon;
    Wood                *_startWood;
    CCNode              *_cloud1;
    CCNode              *_cloud2;
    Wave                *_rearWave1;
    Wave                *_rearWave2;
    WaveLightBlue       *_frontWave1;
    WaveLightBlue       *_frontWave2;
    CCButton            *_restartButton;
    CCLabelTTF          *_scoreLabel;
    NSArray             *_clouds;
    NSArray             *_frontWaves;
    NSArray             *_rearWaves;
    
    
    NSTimeInterval      _sinceTouch;
    NSMutableArray      *_enemies;
    NSMutableArray      *_tools;
    NSMutableArray      *_weapons;
    BOOL                _gameOver;
    int                 _distance;
    BOOL                dragTool;
    BOOL                dragWeapon;
    Wood                *_prevWood;
    float               _timeSinceObstacle;
}
-(void) gameOver;
@end
