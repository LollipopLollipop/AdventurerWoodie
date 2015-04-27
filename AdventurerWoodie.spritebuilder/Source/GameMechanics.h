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



@interface GameMechanics : CCNode <CCPhysicsCollisionDelegate>

- (void)placeTool;//abstract
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
