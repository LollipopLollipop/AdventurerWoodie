//
//  GameScene.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 3/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "GameScene.h"
#import "WoodieWalkRight.h"
#import "Shark.h"
#import "Wood.h"
#include <stdlib.h>
#import "CCPhysics+ObjectiveChipmunk.h"

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


@implementation GameScene{
    
    CGPoint _cloudParallaxRatio;
    CCNode *_parallaxContainer;
    CCParallaxNode *_parallaxBackground;
    
    //background clouds
    CCNode *_cloud1;
    CCNode *_cloud2;
    NSArray *_clouds;
    //background waves
    
    NSArray *_frontWaves;
    NSArray *_rearWaves;
    

    NSTimeInterval _sinceTouch;
    //array of randomly placed obstacles (sharks in level 1)
    NSMutableArray *_obstacles;
    NSMutableArray *_woods;
    CCButton *_restartButton;
    BOOL _gameOver;
    CCLabelTTF *_scoreLabel;
    int _distance;
}


// is called when CCB file has completed loading
- (void)didLoadFromCCB {
    CCLOG(@"call super init");
    [super initialize];
    
    self.userInteractionEnabled = TRUE;
    _staticPhyNode.debugDraw = TRUE;
    _physicsNode.debugDraw = TRUE;
    
    
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
    
    _obstacles = [NSMutableArray array];
    _woods = [NSMutableArray array];
    _distance = 0;
    _scoreLabel.visible = true;
    
    // nothing shall collide with our invisible nodes
    _pullbackNode.physicsBody.collisionMask = @[];
    _bottomPullBack.physicsBody.collisionMask = @[];
    
    
}

#pragma mark - Touch Handling
// called on every touch in this scene
- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    if (!_gameOver) {
        _sinceTouch = 0.f;
        
        @try
        {
            //[super touchBegan:touch withEvent:event];
            CGPoint touchLocation = [touch locationInNode:self];
            
            // start catapult dragging when a touch inside of the catapult arm occurs
            if (CGRectContainsPoint([_readyWood boundingBox], touchLocation))
            {
                // move the mouseJointNode to the touch position
                _mouseJointNode.position = touchLocation;
                
                // setup a spring joint between the mouseJointNode and the catapultArm
                _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_readyWood.physicsBody anchorA:ccp(0, 0) anchorB:ccp(29, 10) restLength:0.f stiffness:3000.f damping:150.f];
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
    CGPoint touchLocation = [touch locationInNode:self];
    [self placeWood:touchLocation];
    [self releaseReadyWood];
}

- (void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    CGPoint touchLocation = [touch locationInNode:self];
    [self placeWood:touchLocation];
    [self releaseReadyWood];
}

- (void)releaseReadyWood {
    if (_mouseJoint != nil) {
        // releases the joint and lets the catpult snap back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        _readyWood.position = ccp(50,180);
    }
}


#pragma mark - Game Actions

- (void)gameOver {
    if (!_gameOver) {
        _gameOver = TRUE;
        _restartButton.visible = TRUE;
        //comes with FB check later
        _character.physicsBody.velocity = ccp(0.0f, 0.0f);
        _character.physicsBody.allowsRotation = FALSE;
        [_character stopAllActions];
        
        CCActionMoveBy *moveBy = [CCActionMoveBy actionWithDuration:0.2f position:ccp(-2, 2)];
        CCActionInterval *reverseMovement = [moveBy reverse];
        CCActionSequence *shakeSequence = [CCActionSequence actionWithArray:@[moveBy, reverseMovement]];
        CCActionEaseBounce *bounce = [CCActionEaseBounce actionWithAction:shakeSequence];
        
        [self runAction:bounce];
    }
}

- (void)restart {
    CCScene *scene = [CCBReader loadAsScene:@"GameScene"];
    [[CCDirector sharedDirector] replaceScene:scene];
    
}

#pragma mark - Obstacle Spawning
- (void)addObstacle
{
    Shark *shark = (Shark *)[CCBReader load:@"Shark"];
    
    CGPoint screenPosition = [self convertToWorldSpace:ccp(0, 0)];//y position is fixed at 0
    CGPoint worldPosition = [_physicsNode convertToNodeSpace:screenPosition];
    
    shark.position = worldPosition;
    [shark setupRandomPosition];
    [_physicsNode addChild:shark];
    [_obstacles addObject:shark];
}

#pragma mak - Wood Placement
- (void)placeWood:(CGPoint)touchLocation
{
    CGPoint screenPosition = [self convertToWorldSpace:touchLocation];
    CGPoint worldPosition = [_physicsNode convertToNodeSpace:screenPosition];
    //place the wood on the touch location
    Wood* wood= (Wood*)[CCBReader load:@"Wood"];
    wood.position = worldPosition;
    //add new wood to the parent physics node
    [_physicsNode addChild:wood];
    [_woods addObject:wood];
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
    
    /*character.rotation = clampf(character.rotation, -30.f, 90.f);
    
    if (character.physicsBody.allowsRotation) {
        float angularVelocity = clampf(character.physicsBody.angularVelocity, -2.f, 1.f);
        character.physicsBody.angularVelocity = angularVelocity;
    }
    
    if ((_sinceTouch > 0.5f)) {
        [character.physicsBody applyAngularImpulse:-40000.f*delta];
    }*/
    
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
    
    
    NSMutableArray *offScreenObstacles = nil;
    NSMutableArray *offScreenWoods = nil;
    
    for (CCNode *obstacle in _obstacles) {
        CGPoint obstacleWorldPosition = [_physicsNode convertToWorldSpace:obstacle.position];
        CGPoint obstacleScreenPosition = [self convertToNodeSpace:obstacleWorldPosition];
        if (obstacleScreenPosition.x < -50) {
            if (!offScreenObstacles) {
                offScreenObstacles = [NSMutableArray array];
            }
            [offScreenObstacles addObject:obstacle];
        }
    }
    
    for (CCNode *obstacleToRemove in offScreenObstacles) {
        CCLOG(@"REMOVE");
        [obstacleToRemove removeFromParent];
        [_obstacles removeObject:obstacleToRemove];
    }
    
    for (CCNode *wood in _woods) {
        CGPoint woodWorldPosition = [_physicsNode convertToWorldSpace:wood.position];
        CGPoint woodScreenPosition = [self convertToNodeSpace:woodWorldPosition];
        if (woodScreenPosition.x < -wood.contentSize.width) {
            if (!offScreenWoods) {
                offScreenWoods = [NSMutableArray array];
            }
            [offScreenWoods addObject:wood];
        }
    }
    
    for (CCNode *woodToRemove in offScreenWoods) {
        CCLOG(@"REMOVE");
        [woodToRemove removeFromParent];
        [_woods removeObject:woodToRemove];
    }
    
    
    if (!_gameOver)
    {
        @try
        {
            //character.physicsBody.velocity = ccp(10.f, clampf(character.physicsBody.velocity.y, -MAXFLOAT, 50.f));
            _character.physicsBody.velocity = ccp(50.f,0.f);
            
            [super update:delta];
        }
        @catch(NSException* ex)
        {
            
        }
    }
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair character:(CCSprite*)character wave:(CCNode*)wave {
    CCLOG(@"DROWN");
    [self gameOver];
    return TRUE;
}
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair character:(CCSprite*)character crash:(CCNode*)crash {
    CCLOG(@"EATEN");
    [self gameOver];
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair character:(CCNode *)character wood:(CCNode *)wood {
    CCLOG(@"SAFE");
    //[goal removeFromParent];
    _distance+=50;
    _scoreLabel.string = [NSString stringWithFormat:@"%d", _distance];
    return TRUE;
}
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair wood:(CCNode *)wood crash:(CCNode*)crash {
    CCLOG(@"Overlap");
    [self woodEaten:wood];
    return TRUE;
}

- (void)woodEaten:(CCNode *)wood {
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
    [_woods removeObject:wood];
}

@end

