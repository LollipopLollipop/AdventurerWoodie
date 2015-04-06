//
//  Level1.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 4/4/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Level1.h"
#import "WoodieWalkRight.h"
#import "Shark.h"
#import "Wood.h"
#include <stdlib.h>
#import "CCPhysics+ObjectiveChipmunk.h"
#import "Weapon.h"

@interface CGPointObject : NSObject
{
    CGPoint _ratio;
    CGPoint _offset;
    CCNode *__unsafe_unretained _child; // weak ref
}
@property (nonatomic,readwrite) CGPoint ratio;
@property (nonatomic,readwrite) CGPoint offset;
@property (nonatomic,readwrite,unsafe_unretained) CCNode *child;
+(id) pointWithCGPoint:(CGPoint)point offset:(CGPoint)offset;
-(id) initWithCGPoint:(CGPoint)point offset:(CGPoint)offset;
@end



@implementation Level1

- (void)didLoadFromCCB {
    _startStation.zOrder = DrawingOrderTool;
    _startStation.physicsBody.collisionType = @"station";
    _timeSinceObstacle = 0.0f;
    self.userInteractionEnabled = TRUE;
    //_staticPhyNode.debugDraw = TRUE;
    //_physicsNode.debugDraw = TRUE;
    
    _clouds = @[_cloud1, _cloud2];
    _frontWaves = @[_frontWave1, _frontWave2];
    _rearWaves = @[_rearWave1, _rearWave2];
    
    _parallaxBackground = [CCParallaxNode node];
    [_parallaxContainer addChild:_parallaxBackground];

    _cloudParallaxRatio = ccp(0.5, 1);
    
    for (CCNode *cloud in _clouds) {
        CGPoint offset = cloud.position;
        [self removeChild:cloud];
        [_parallaxBackground addChild:cloud z:0 parallaxRatio:_cloudParallaxRatio positionOffset:offset];
    }
    
    //The delegate object that you want to respond to collisions for the collision behavior.
    _physicsNode.collisionDelegate = self;
    
    _enemies = [NSMutableArray array];
    _tools = [NSMutableArray array];
    _weapons = [NSMutableArray array];
    _distance = 0;
    _scoreLabel.visible = true;
    
    // nothing shall collide with our invisible nodes
    _pullbackNode.physicsBody.collisionMask = @[];
    _bottomPullBack.physicsBody.collisionMask = @[];
    _weaponPullbackNode.physicsBody.collisionMask = @[];
    _weaponBottomPullBack.physicsBody.collisionMask = @[];
    _prevWood = _startWood;
}

#pragma mark - Touch Handling
// called on every touch in this scene
- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    if (!_gameOver) {
        _sinceTouch = 0.f;
        
        @try
        {
            CGPoint touchLocation = [touch locationInNode:self];
            // start catapult dragging when a touch inside of the ready wood occurs
            if (CGRectContainsPoint([_readyWood boundingBox], touchLocation))
            {
                dragTool = TRUE;
                CCLOG(@"DRAG WOOD");
                // move the mouseJointNode to the touch position
                _mouseJointNode.position = touchLocation;
                
                // setup a spring joint between the mouseJointNode and the catapultArm
                _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_readyWood.physicsBody anchorA:ccp(0, 0) anchorB:ccp(29, 10) restLength:0.f stiffness:5000.f damping:150.f];
            }
            else if (CGRectContainsPoint([_weapon boundingBox], touchLocation))
            {
                dragWeapon = TRUE;
                CCLOG(@"DRAG WEAPON");
                // move the mouseJointNode to the touch position
                _mouseJointNode.position = touchLocation;
                
                // setup a spring joint between the mouseJointNode and the catapultArm
                _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_weapon.physicsBody anchorA:ccp(0, 0) anchorB:ccp(45.50, 54.50) restLength:0.f stiffness:3000.f damping:150.f];
            }
            
        }
        @catch(NSException* ex)
        {
            
        }
    }
}

- (void)touchMoved:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    // whenever touches move, update the position of the mouseJointNode to the touch position
    CGPoint touchLocation = [touch locationInNode:self];
    _mouseJointNode.position = touchLocation;
}

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    
    if(dragTool){
        CCLOG(@"PLACE WOOD");
        CGPoint touchLocation = [touch locationInNode:self];
        [self placeTool:touchLocation];
        [self releaseTool];
    }
    if(dragWeapon){
        CCLOG(@"MOVE WEAPON");
        //_weapon.physicsBody.velocity =
        //[_weapon.physicsBody applyImpulse:ccp(0, 400.f)];
        [self applyWeapon];
        [self releaseWeapon];
    }
}

- (void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    if(dragTool){
        CCLOG(@"PLACE WOOD");
        CGPoint touchLocation = [touch locationInNode:self];
        [self placeTool:touchLocation];
        [self releaseTool];
    }
    if(dragWeapon){
        CCLOG(@"MOVE WEAPON");
        //_weapon.physicsBody.velocity =
        //[_weapon.physicsBody applyImpulse:ccp(0, 400.f)];
        [self applyWeapon];
        [self releaseWeapon];
    }

}
#pragma mark - Release Dragged Obj
- (void)releaseTool {
    if (_mouseJoint != nil) {
        // releases the joint and lets the catpult snap back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        _readyWood.position = ccp(50,180);
        dragTool = FALSE;
    }
}
- (void)releaseWeapon {
    if (_mouseJoint != nil) {
        // releases the joint and lets the catpult snap back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        _weapon.position = ccp(500,250);
        dragWeapon = FALSE;
    }
}

#pragma mark - Apply Dragged Obj
- (void)placeTool:(CGPoint)touchLocation
{
    CGPoint worldPosition = [self convertToWorldSpace:_readyWood.position];
    CGPoint screenPosition = [_physicsNode convertToNodeSpace:worldPosition];
    CCLOG(@"ready wood screen pos %f %f", screenPosition.x, screenPosition.y);
    CCLOG(@"prev wood pos %f %f", _prevWood.position.x, _prevWood.position.y);
    Wood* wood= (Wood*)[CCBReader load:@"Wood"];
    if(CGRectContainsPoint([_prevWood boundingBox], screenPosition))
    {
        CCLOG(@"INSIDE BOUNDING BOX");
        wood.position = ccp(_prevWood.position.x+58, _prevWood.position.y);
        [_physicsNode addChild:wood];
        [_tools addObject:wood];
        _prevWood = wood;
    }
    else
    {
        CCLOG(@"NOT INSIDE BOUNDING BOX");
        wood.position = screenPosition;
        [_physicsNode addChild:wood];
        [_tools addObject:wood];
        CGPoint launchDirection = ccp(0, -1);
        CGPoint force = ccpMult(launchDirection, 8000);
        [wood.physicsBody applyForce:force];
    }
    
}
- (void)applyWeapon
{
    CGPoint launchDirection = ccp(0, -1);
    CGPoint force = ccpMult(launchDirection, 8000);
    [_weapon.physicsBody applyForce:force];
    CGPoint worldPosition = [self convertToWorldSpace:_weapon.position];
    CGPoint screenPosition = [_physicsNode convertToNodeSpace:worldPosition];
    Weapon* invisibleWeapon= (Weapon*)[CCBReader load:@"Weapon"];
    invisibleWeapon.position = screenPosition;
    [_physicsNode addChild:invisibleWeapon];
    [_weapons addObject:invisibleWeapon];
}

#pragma mark - Game Actions

- (void)gameOver {
    if (!_gameOver) {
        CCLOG(@"GAME OVER");
        _gameOver = TRUE;
        _restartButton.visible = TRUE;
        //comes with FB check later
        _character.physicsBody.velocity = ccp(0.0f, 0.0f);
        _character.physicsBody.allowsRotation = FALSE;
        [_character stopAllActions];
        
        /*
        CCActionMoveBy *moveBy = [CCActionMoveBy actionWithDuration:0.2f position:ccp(-2, 2)];
        CCActionInterval *reverseMovement = [moveBy reverse];
        CCActionSequence *shakeSequence = [CCActionSequence actionWithArray:@[moveBy, reverseMovement]];
        CCActionEaseBounce *bounce = [CCActionEaseBounce actionWithAction:shakeSequence];
        
        [self runAction:bounce];*/
    }
}

- (void)restart {
    CCScene *scene = [CCBReader loadAsScene:@"Level1"];
    [[CCDirector sharedDirector] replaceScene:scene];
    //CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    //[[CCDirector sharedDirector] presentScene:scene withTransition:transition];
    
}

#pragma mark - Obstacle Spawning
- (void)addEnemy
{
    Shark *shark = (Shark *)[CCBReader load:@"Shark"];
    
    CGPoint worldPosition = [self convertToWorldSpace:ccp(0, 10)];//y position is fixed at 0
    CGPoint screenPosition = [_physicsNode convertToNodeSpace:worldPosition];
    
    shark.position = screenPosition;
    [shark setupRandomPosition];
    [_physicsNode addChild:shark];
    [_enemies addObject:shark];
}


#pragma mark - Update

- (void)showScore
{
    _scoreLabel.string = [NSString stringWithFormat:@"%d", _distance];
    _scoreLabel.visible = true;
}


- (void)update:(CCTime)delta
{
    _sinceTouch += delta;
    _distance+=delta*_character.physicsBody.velocity.x;
    _scoreLabel.string = [NSString stringWithFormat:@"%d", _distance];
    
    _physicsNode.position = ccp(_physicsNode.position.x - (_character.physicsBody.velocity.x * delta), _physicsNode.position.y);
    
    
    // loop the wave
    for (WaveLightBlue *frontWave in _frontWaves) {
        // get the world position of the ground
        CGPoint waveWorldPosition = [_physicsNode convertToWorldSpace:frontWave.position];
        // get the screen position of the ground
        CGPoint waveScreenPosition = [self convertToNodeSpace:waveWorldPosition];
        
        // if the left corner is one complete width off the screen, move it to the right
        if (waveScreenPosition.x <= -960) {
            frontWave.position = ccp(frontWave.position.x + 2 * 960, frontWave.position.y);
        }
    }
    for (Wave *rearWave in _rearWaves) {
        // get the world position of the ground
        CGPoint waveWorldPosition = [_physicsNode convertToWorldSpace:rearWave.position];
        // get the screen position of the ground
        CGPoint waveScreenPosition = [self convertToNodeSpace:waveWorldPosition];
        
        // if the left corner is one complete width off the screen, move it to the right
        if (waveScreenPosition.x <= -960) {
            rearWave.position = ccp(rearWave.position.x + 2 * 960, rearWave.position.y);
        }
    }
    
    _parallaxBackground.position = ccp(_parallaxBackground.position.x - (_character.physicsBody.velocity.x * delta), _parallaxBackground.position.y);
    
    
    // loop the clouds
    for (CCNode *cloud in _clouds) {
        // get the world position of the cloud
        CGPoint cloudWorldPosition = [_parallaxBackground convertToWorldSpace:cloud.position];
        // get the screen position of the cloud
        CGPoint cloudScreenPosition = [self convertToNodeSpace:cloudWorldPosition];
        
        // if the left corner is one complete width off the screen,
        // move it to the right
        if (cloudScreenPosition.x <= (-1 * cloud.contentSize.width)) {
            for (CGPointObject *child in _parallaxBackground.parallaxArray) {
                if (child.child == cloud) {
                    child.offset = ccp(child.offset.x + 2*cloud.contentSize.width, child.offset.y);
                }
            }
        }
    }
    
    //remove created objects
    NSMutableArray *offScreenEnemies = nil;
    NSMutableArray *offScreenTools = nil;
    NSMutableArray *offScreenWeapons = nil;
    
    for (CCNode *enemy in _enemies) {
        CGPoint enemyWorldPosition = [_physicsNode convertToWorldSpace:enemy.position];
        CGPoint enemyScreenPosition = [self convertToNodeSpace:enemyWorldPosition];
        if (enemyScreenPosition.x < -50) {
            if (!offScreenEnemies) {
                offScreenEnemies = [NSMutableArray array];
            }
            [offScreenEnemies addObject:enemy];
        }
    }
    
    for (CCNode *enemyToRemove in offScreenEnemies) {
        CCLOG(@"REMOVE");
        [enemyToRemove removeFromParent];
        [_enemies removeObject:enemyToRemove];
    }
    
    for (CCNode *tool in _tools) {
        CGPoint toolWorldPosition = [_physicsNode convertToWorldSpace:tool.position];
        CGPoint toolScreenPosition = [self convertToNodeSpace:toolWorldPosition];
        if (toolScreenPosition.x < -tool.contentSize.width) {
            if (!offScreenTools) {
                offScreenTools = [NSMutableArray array];
            }
            [offScreenTools addObject:tool];
        }
    }
    
    for (CCNode *toolToRemove in offScreenTools) {
        CCLOG(@"REMOVE");
        [toolToRemove removeFromParent];
        [_tools removeObject:toolToRemove];
    }
    
    for (CCNode *weapon in _weapons) {
        CGPoint weaponWorldPosition = [_physicsNode convertToWorldSpace:weapon.position];
        CGPoint weaponScreenPosition = [self convertToNodeSpace:weaponWorldPosition];
        if (weaponScreenPosition.x < -weapon.contentSize.width) {
            if (!offScreenWeapons) {
                offScreenWeapons = [NSMutableArray array];
            }
            [offScreenWeapons addObject:weapon];
        }
    }
    
    for (CCNode *weaponToRemove in offScreenWeapons) {
        CCLOG(@"REMOVE");
        [weaponToRemove removeFromParent];
        [_weapons removeObject:weaponToRemove];
    }
    
    
    if (!_gameOver)
    {
        CCLOG(@"NOT GAME OVER");
        @try
        {
            _character.physicsBody.velocity = ccp(10.f, 0.f);
            //Increment the time since the last obstacle was added
            _timeSinceObstacle += delta;
            
            //Check to see if two seconds have passed
            if (_timeSinceObstacle > 10.0f)
            {
                //Add a new enemy
                [self addEnemy];
                //Then reset the timer
                _timeSinceObstacle = 0.0f;
                
            }
        }
        @catch(NSException* ex)
        {
            
        }
    }
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero ground:(CCNode*)ground {
    CCLOG(@"DROWN");
    //implement drowning effect
    [self gameOver];
    return TRUE;
}
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero enemy:(CCNode*)enemy {
    CCLOG(@"EATEN");
    //implement effect of killed by enemies
    [self gameOver];
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair tool:(CCSprite *)tool enemy:(CCNode*)enemy {
    CCLOG(@"Overlap");
    
    [self toolDestroyed:tool];
    return TRUE;
}
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair enemy:(CCNode *)enemy weapon:(CCSprite*)weapon {
    CCLOG(@"Kill");
    [self enemyKilled:enemy];
    return TRUE;
}
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair enemy:(CCNode *)enemy station:(CCNode*)station {
    CCLOG(@"Kill");
    [self enemyKilled:enemy];
    return TRUE;
}

- (void)toolDestroyed:(CCSprite *)wood {
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"WoodEaten"];
    // place the particle effect on the wood position
    explosion.position = wood.position;
    // add the particle effect to the same node the wood is on
    [wood.parent addChild:explosion];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = YES;
    
    // finally, remove the destroyed seal
    [wood removeFromParent];
    [_tools removeObject:wood];
}
- (void)enemyKilled:(CCNode *)shark {
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"SharkKilled"];
    // place the particle effect on the wood position
    explosion.position = shark.position;
    // add the particle effect to the same node the wood is on
    [shark.parent addChild:explosion];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = YES;
    
    // finally, remove the destroyed seal
    [shark removeFromParent];
    [_enemies removeObject:shark];
}

@end
