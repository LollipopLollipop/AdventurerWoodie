//
//  GameMechanics.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 3/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "GameMechanics.h"
#import "Weapon.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#include <stdlib.h>
#import "Shark.h"
#import "Wood.h"


static NSString * const kFirstLevel = @"Level1";
static NSString *selectedLevel = @"Level1";
static NSString *selectedLevelSetting = @"LevelSetting1";
static int levelSpeed = 0;

@implementation GameMechanics
{
    //variable representing different scene component
    CCSprite            *_character;
    CCPhysicsNode       *_staticPhyNode;
    CCPhysicsNode       *_movingNode;
    CCNode              *_settingNode;
    CCNode              *_startStation;
    CCNode              *_startTool;
    CCNode              *_prevTool;
    CCNode              *_pullbackNode;
    CCNode              *_bottomPullBack;
    CCNode              *_weaponPullbackNode;
    CCNode              *_weaponBottomPullBack;
    CCNode              *_mouseJointNode;
    CCPhysicsJoint      *_mouseJoint;
    CCNode              *_readyTool;
    CCNode              *_weapon;
    CCNode              *_cloudNode;
    CCNode              *_cloud1;
    CCNode              *_cloud2;
    CCNode              *_rearGround1;
    CCNode              *_rearGround2;
    CCNode              *_frontGround1;
    CCNode              *_frontGround2;
    CCButton            *_restartButton;
    CCLabelTTF          *_scoreLabel;
    NSArray             *_clouds;
    NSArray             *_frontGrounds;
    NSArray             *_rearGrounds;
    
    
    NSTimeInterval      _sinceTouch;
    NSMutableArray      *_enemies;
    NSMutableArray      *_tools;
    NSMutableArray      *_weapons;
    BOOL                _gameOver;
    BOOL                _danger;
    int                 _distance;
    BOOL                dragTool;
    BOOL                dragWeapon;
    float               _timeSinceEnemy;
    float               _timeSinceSafeStep;
    Level               *_loadedLevel;
    LevelSetting        *_loadedLevelSetting;

}

#pragma mark - Node Lifecycle

- (void)didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
    //The delegate object that you want to respond to collisions for the collision behavior.
    //_staticPhyNode.collisionDelegate = self;
    _movingNode.collisionDelegate = self;
    
    //_rearGround1.zOrder = DrawingOrderRearGround;
    //_rearGround2.zOrder = DrawingOrderRearGround;
    //_startStation.zOrder = DrawingOrderTool;
    //_character.zOrder = DrawingOrderHero;
    //_weapon.zOrder = DrawingOrderWeapon;
    //_frontGround1.zOrder = DrawingOrderFrontGround;
    //_frontGround2.zOrder = DrawingOrderFrontGround;
    
    
    
    
    _loadedLevel = (Level *) [CCBReader load:selectedLevel owner:self];
    [_movingNode addChild:_loadedLevel];
    _loadedLevelSetting = (LevelSetting *) [CCBReader load:selectedLevelSetting owner:self];
    [_settingNode addChild:_loadedLevelSetting];
    
    levelSpeed = _loadedLevel.levelSpeed;
    
    /*
    _startStation.physicsBody.collisionType = @"station";
    _frontGround1.physicsBody.collisionType = @"ground";
    _frontGround2.physicsBody.collisionType = @"ground";
    _rearGround1.physicsBody.collisionType = @"ground";
    _rearGround2.physicsBody.collisionType = @"ground";
    _weapon.physicsBody.collisionType = @"weapon";*/
    _timeSinceEnemy = 0.0f;
    _timeSinceSafeStep = 0.0f;
    //_staticPhyNode.debugDraw = TRUE;
    //_physicsNode.debugDraw = TRUE;
    _clouds = @[_cloud1, _cloud2];
    _frontGrounds = @[_frontGround1, _frontGround2];
    _rearGrounds = @[_rearGround1, _rearGround2];
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
    _prevTool = _startTool;
    CCLOG(@"PREV TOOL LOC %f, %f", _prevTool.position.x, _prevTool.position.y);
    _character.physicsBody.sensor = YES;
}

#pragma mark - Touch Handling
// called on every touch in this scene
- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    if (!_gameOver) {
        _sinceTouch = 0.f;
        
        @try
        {
            CGPoint touchLocation = [touch locationInNode:self];
            CCLOG(@"TOUCH LOC %f, %f", touchLocation.x, touchLocation.y);
            // start catapult dragging when a touch inside of the ready wood occurs
            if (CGRectContainsPoint([_readyTool boundingBox], touchLocation))
            {
                dragTool = TRUE;
                //CCLOG(@"DRAG WOOD");
                // move the mouseJointNode to the touch position
                _mouseJointNode.position = touchLocation;
                
                // setup a spring joint between the mouseJointNode and the catapultArm
                _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_readyTool.physicsBody anchorA:ccp(0, 0) anchorB:ccp(29, 10) restLength:0.f stiffness:5000.f damping:150.f];
            }
            else if (CGRectContainsPoint([_weapon boundingBox], touchLocation))
            {
                dragWeapon = TRUE;
                //CCLOG(@"DRAG WEAPON");
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
        //CCLOG(@"PLACE WOOD");
        //CGPoint touchLocation = [touch locationInNode:self];
        [self placeTool];
        [self releaseTool];
    }
    if(dragWeapon){
        //CCLOG(@"MOVE WEAPON");
        //_weapon.physicsBody.velocity =
        //[_weapon.physicsBody applyImpulse:ccp(0, 400.f)];
        [self applyWeapon];
        [self releaseWeapon];
    }
}

- (void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    if(dragTool){
        //CCLOG(@"PLACE WOOD");
        //CGPoint touchLocation = [touch locationInNode:self];
        [self placeTool];
        [self releaseTool];
    }
    if(dragWeapon){
        //CCLOG(@"MOVE WEAPON");
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
        _readyTool.position = ccp(50,180);
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
- (void)placeTool
{
    //CCLOG(@"ready wood orig pos %f %f", _readyTool.position.x, _readyTool.position.y);
    CGPoint worldPosition = [self convertToWorldSpace:_readyTool.position];
    CGPoint screenPosition = [_movingNode convertToNodeSpace:worldPosition];
    //CCLOG(@"ready wood screen pos %f %f", screenPosition.x, screenPosition.y);
    //CCLOG(@"prev wood pos %f %f", _prevTool.position.x, _prevTool.position.y);
    Wood* wood= (Wood*)[CCBReader load:@"Wood"];
    if(CGRectContainsPoint([_prevTool boundingBox], screenPosition))
    {
        //CCLOG(@"INSIDE BOUNDING BOX");
        wood.position = ccp(_prevTool.position.x+58, _prevTool.position.y);
        [_movingNode addChild:wood];
        //[_staticPhyNode addChild:wood];
        [_tools addObject:wood];
        _prevTool = wood;
        CCLOG(@"PREV TOOL LOC %f, %f", _prevTool.position.x, _prevTool.position.y);
    }
    else
    {
        //CCLOG(@"NOT INSIDE BOUNDING BOX");
        wood.position = screenPosition;
        [_movingNode addChild:wood];
        //[_staticPhyNode addChild:wood];
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
    CGPoint screenPosition = [_movingNode convertToNodeSpace:worldPosition];
    Weapon* invisibleWeapon= (Weapon*)[CCBReader load:@"Weapon"];
    invisibleWeapon.position = screenPosition;
    [_movingNode addChild:invisibleWeapon];
    [_weapons addObject:invisibleWeapon];
}

#pragma mark - Obstacle Spawning
- (void)addEnemy
{
    Shark *shark = (Shark *)[CCBReader load:@"Shark"];
    
    CGPoint worldPosition = [self convertToWorldSpace:ccp(0, 10)];//y position is fixed at 0
    CGPoint screenPosition = [_movingNode convertToNodeSpace:worldPosition];
    
    shark.position = screenPosition;
    [shark setupRandomPosition];
    [_movingNode addChild:shark];
    [_enemies addObject:shark];
    //CCLOG(@"ADD SHARK");
    //CCLOG(@"ENEMIES COUNT %lu", [_enemies count]);
}



#pragma mark - Game Actions

- (void)gameOver {
    if (!_gameOver) {
        //CCLOG(@"GAME OVER");
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

- (void) getInDanger {
    if(!_danger) {
        _danger = TRUE;
        _character.physicsBody.velocity = ccp(0.0f, 0.0f);
        _character.physicsBody.allowsRotation = FALSE;
        [_character stopAllActions];
        CCLOG(@"DANGER");
    }
}
- (void)restart {
    CCScene *scene = [CCBReader loadAsScene:@"GameMechanics"];
    [[CCDirector sharedDirector] replaceScene:scene];
    //CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    //[[CCDirector sharedDirector] presentScene:scene withTransition:transition];
    
}

#pragma mark - Update

- (void)showScore
{
    CCLOG(@"SHOW SCORE");
    //_distance+=0.0665*_character.physicsBody.velocity.x;
    //_scoreLabel.string = [NSString stringWithFormat:@"%d", _distance];
    //_scoreLabel.visible = true;
}


- (void)update:(CCTime)delta
{
    //CCLOG(@"delta is %f", delta);
    _sinceTouch += delta;
    //CCLOG(@"HERO SPEED IS %f", _character.physicsBody.velocity.x);
    //calc and display current distance conquered
    _distance+=delta*_character.physicsBody.velocity.x*10;
    //CCLOG(@"distance is %d", _distance);
    _scoreLabel.string = [NSString stringWithFormat:@"%d", _distance];
    
    //screen view move in the same pace as the main character
    _movingNode.position = ccp(_movingNode.position.x - (_character.physicsBody.velocity.x * delta), _movingNode.position.y);
    _cloudNode.position = ccp(_cloudNode.position.x - ((_character.physicsBody.velocity.x/2)*delta), _cloudNode.position.y);
    
    
    // loop the ground
    for (CCNode *frontGround in _frontGrounds) {
        // get the world position of the ground
        CGPoint worldPosition = [_movingNode convertToWorldSpace:frontGround.position];
        // get the screen position of the ground
        CGPoint screenPosition = [self convertToNodeSpace:worldPosition];
        
        // if the left corner is one complete width off the screen, move it to the right
        if (screenPosition.x <= -960) {
            frontGround.position = ccp(frontGround.position.x + 2 * 960, frontGround.position.y);
        }
    }
    for (CCNode *rearGround in _rearGrounds) {
        // get the world position of the ground
        CGPoint worldPosition = [_movingNode convertToWorldSpace:rearGround.position];
        // get the screen position of the ground
        CGPoint screenPosition = [self convertToNodeSpace:worldPosition];
        
        // if the left corner is one complete width off the screen, move it to the right
        if (screenPosition.x <= -960) {
            rearGround.position = ccp(rearGround.position.x + 2 * 960, rearGround.position.y);
        }
    }
    
    // loop the clouds
    for (CCNode *cloud in _clouds) {
        // get the world position of the cloud
        CGPoint cloudWorldPosition = [_cloudNode convertToWorldSpace:cloud.position];
        // get the screen position of the cloud
        CGPoint cloudScreenPosition = [self convertToNodeSpace:cloudWorldPosition];
        
        // if the left corner is one complete width off the screen,
        // move it to the right
        if (cloudScreenPosition.x <= (-1 * cloud.contentSize.width)) {
            cloud.position = ccp(cloud.position.x+2*cloud.contentSize.width, cloud.position.y);
        }
    }
    
    //remove created objects
    NSMutableArray *offScreenEnemies = nil;
    NSMutableArray *offScreenTools = nil;
    NSMutableArray *offScreenWeapons = nil;
    
    for (CCNode *enemy in _enemies) {
        CGPoint enemyWorldPosition = [_movingNode convertToWorldSpace:enemy.position];
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
        CGPoint toolWorldPosition = [_movingNode convertToWorldSpace:tool.position];
        CGPoint toolScreenPosition = [self convertToNodeSpace:toolWorldPosition];
        if (toolScreenPosition.x < -tool.contentSize.width) {
            if (!offScreenTools) {
                offScreenTools = [NSMutableArray array];
            }
            [offScreenTools addObject:tool];
        }
    }
    
    for (CCNode *toolToRemove in offScreenTools) {
        //CCLOG(@"REMOVE");
        [toolToRemove removeFromParent];
        [_tools removeObject:toolToRemove];
    }
    
    for (CCNode *weapon in _weapons) {
        CGPoint weaponWorldPosition = [_movingNode convertToWorldSpace:weapon.position];
        CGPoint weaponScreenPosition = [self convertToNodeSpace:weaponWorldPosition];
        if (weaponScreenPosition.x < -weapon.contentSize.width) {
            if (!offScreenWeapons) {
                offScreenWeapons = [NSMutableArray array];
            }
            [offScreenWeapons addObject:weapon];
        }
    }
    
    for (CCNode *weaponToRemove in offScreenWeapons) {
        //CCLOG(@"REMOVE");
        [weaponToRemove removeFromParent];
        [_weapons removeObject:weaponToRemove];
    }
    
    _timeSinceSafeStep += delta;
    if(_timeSinceSafeStep > 6.0f)
    {
        //CCLOG(@"EXCEEDS 6");
        //hero drops into sea water if not step onto tool
        /*_character.physicsBody.velocity = ccp(0.f,0.f);
         [_character stopAllActions];
         CGPoint launchDirection = ccp(0, -1);
         CGPoint force = ccpMult(launchDirection, 4000);
         [_character.physicsBody applyForce:force];*/
        [self getInDanger];
    }
    
    if (!_gameOver && !_danger)
    {
        CCLOG(@"NOT GAME OVER and NO DANGER");
        @try
        {
            _character.physicsBody.velocity = ccp(levelSpeed, 2.f);
            //Increment the time since the last obstacle was added
            _timeSinceEnemy += delta;
            
            //CCLOG(@"time since safe step is %f", _timeSinceSafeStep);
            //Check to see if two seconds have passed
            if (_timeSinceEnemy > 2.0f)
            {
                //Add a new enemy
                [self addEnemy];
                //Then reset the timer
                _timeSinceEnemy = 0.0f;
                
            }
            
        }
        @catch(NSException* ex)
        {
            
        }
    }
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero ground:(CCNode*)ground {
    CCLOG(@"DROWN");
    [self woodieDrown:hero];
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
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite *)hero tool:(CCSprite*)tool {
    CCLOG(@"SAFE");
    //[self showScore];
    _timeSinceSafeStep = 0.0f;
    return TRUE;
}
    

- (void)toolDestroyed:(CCSprite *)tool {
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"WoodEaten"];
    // place the particle effect on the wood position
    explosion.position = tool.position;
    // add the particle effect to the same node the wood is on
    [tool.parent addChild:explosion];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = YES;
    
    // finally, remove the destroyed seal
    [tool removeFromParent];
    [_tools removeObject:tool];
}
- (void)enemyKilled:(CCNode *)enemy {
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"SharkKilled"];
    // place the particle effect on the wood position
    explosion.position = enemy.position;
    // add the particle effect to the same node the wood is on
    [enemy.parent addChild:explosion];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = YES;
    
    // finally, remove the destroyed seal
    [enemy removeFromParent];
    [_enemies removeObject:enemy];
}
- (void)woodieDrown:(CCSprite *)hero {
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"WoodieDrown"];
    // place the particle effect on the wood position
    explosion.position = hero.position;
    // add the particle effect to the same node the wood is on
    [hero.parent addChild:explosion];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = YES;
    
    // finally, remove the destroyed seal
    [hero removeFromParent];
}

#pragma mark - Level completion

- (void)loadNextLevel {
    selectedLevel = _loadedLevel.nextLevelName;
    
    CCScene *nextScene = nil;
    
    if (selectedLevel) {
        nextScene = [CCBReader loadAsScene:@"GameMechanics"];
    } else {
        selectedLevel = kFirstLevel;
        nextScene = [CCBReader loadAsScene:@"MainScene"];
    }
    
    //CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    //[[CCDirector sharedDirector] presentScene:nextScene withTransition:transition];
}


@end
