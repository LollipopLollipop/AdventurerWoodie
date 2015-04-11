//
//  GameMechanics.h
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 3/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCNode.h"
#import "Wood.h"
#import "Level.h"
#import "LevelSetting.h"


//specify drawing orders of different components at level scenes
typedef NS_ENUM(NSInteger, DrawingOrder) {
    
    DrawingOrderRearGround,
    DrawingOrderTool,
    DrawingOrderHero,
    DrawingOrderEnemy,
    DrawingOrderWeapon,
    DrawingOrderFrontGround
    
};


@interface GameMechanics : CCNode <CCPhysicsCollisionDelegate>

- (void)placeTool;//abstract
- (void)releaseTool;
- (void)applyWeapon;
- (void)releaseWeapon;
- (void)gameOver;
- (void)restart;
- (void)showScore;
- (void)addEnemy;
- (void)toolDestroyed:(CCSprite *)tool;
- (void)enemyKilled:(CCNode *)enemy;
- (void)loadNextLevel;
@end
