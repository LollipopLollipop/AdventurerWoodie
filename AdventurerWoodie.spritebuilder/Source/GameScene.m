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
    CGPoint _waveParallaxRatio;
    
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
    CCButton *_restartButton;
    BOOL _gameOver;
    CCLabelTTF *_scoreLabel;
    int distance;
}


// is called when CCB file has completed loading
- (void)didLoadFromCCB {
    CCLOG(@"call super init");
    [super initialize];
    
    self.userInteractionEnabled = TRUE;
    
    _clouds = @[_cloud1, _cloud2];
    _frontWaves = @[frontWave1, frontWave2];
    _rearWaves = @[rearWave1, rearWave2];
    
    _parallaxBackground = [CCParallaxNode node];
    [_parallaxContainer addChild:_parallaxBackground];
    
    _waveParallaxRatio = ccp(0.7,1);
    _cloudParallaxRatio = ccp(0.5, 1);
    
    for (CCNode *cloud in _clouds) {
        CGPoint offset = cloud.position;
        [self removeChild:cloud];
        [_parallaxBackground addChild:cloud z:0 parallaxRatio:_cloudParallaxRatio positionOffset:offset];
    }
        //The delegate object that you want to respond to collisions for the collision behavior.
    _physicsNode.collisionDelegate = self;
    
    _obstacles = [NSMutableArray array];
    distance = 0;
    _scoreLabel.visible = true;
    
}

#pragma mark - Touch Handling
// called on every touch in this scene
- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    if (!_gameOver) {
        _sinceTouch = 0.f;
        
        @try
        {
            [super touchBegan:touch withEvent:event];
        }
        @catch(NSException* ex)
        {
            
        }
    }
}

#pragma mark - Game Actions

- (void)gameOver {
    if (!_gameOver) {
        _gameOver = TRUE;
        _restartButton.visible = TRUE;
        //comes with FB check later
        character.physicsBody.velocity = ccp(0.0f, 0.0f);
        character.physicsBody.allowsRotation = FALSE;
        [character stopAllActions];
        
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


#pragma mark - Update

- (void)showScore
{
    _scoreLabel.string = [NSString stringWithFormat:@"%d", distance];
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
    
    _physicsNode.position = ccp(_physicsNode.position.x - (character.physicsBody.velocity.x * delta), _physicsNode.position.y);
    _startStation.position = ccp(_startStation.position.x - (character.physicsBody.velocity.x * delta),
                                 _startStation.position.y);
    
    
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
    
    _parallaxBackground.position = ccp(_parallaxBackground.position.x - (character.physicsBody.velocity.x * delta), _parallaxBackground.position.y);
    
    /*
    // loop the waves
    for (Wave *frontWave in _frontWaves) {
        // get the world position of the bush
        CGPoint waveWorldPosition = [_parallaxBackground convertToWorldSpace:frontWave.position];
        // get the screen position of the bush
        CGPoint waveScreenPosition = [self convertToNodeSpace:waveWorldPosition];
        
        // if the left corner is one complete width off the screen,
        // move it to the right
        if (waveScreenPosition.x <= (-1 * frontWave.contentSize.width)) {
            for (CGPointObject *child in _parallaxBackground.parallaxArray) {
                if (child.child == frontWave) {
                    child.offset = ccp(child.offset.x + 2*frontWave.contentSize.width, child.offset.y);
                }
            }
        }
    }
    for (Wave *rearWave in _rearWaves) {
        // get the world position of the bush
        CGPoint waveWorldPosition = [_parallaxBackground convertToWorldSpace:rearWave.position];
        // get the screen position of the bush
        CGPoint waveScreenPosition = [self convertToNodeSpace:waveWorldPosition];
        
        // if the left corner is one complete width off the screen,
        // move it to the right
        if (waveScreenPosition.x <= (-1 * rearWave.contentSize.width)) {
            for (CGPointObject *child in _parallaxBackground.parallaxArray) {
                if (child.child == rearWave) {
                    child.offset = ccp(child.offset.x + 2*rearWave.contentSize.width, child.offset.y);
                }
            }
        }
    }*/
    
    
    
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
    
    for (CCNode *obstacle in _obstacles) {
        CGPoint obstacleWorldPosition = [_physicsNode convertToWorldSpace:obstacle.position];
        CGPoint obstacleScreenPosition = [self convertToNodeSpace:obstacleWorldPosition];
        if (obstacleScreenPosition.x < -obstacle.contentSize.width) {
            if (!offScreenObstacles) {
                offScreenObstacles = [NSMutableArray array];
            }
            [offScreenObstacles addObject:obstacle];
        }
    }
    
    for (CCNode *obstacleToRemove in offScreenObstacles) {
        [obstacleToRemove removeFromParent];
        [_obstacles removeObject:obstacleToRemove];
    }
    
    if (!_gameOver)
    {
        @try
        {
            //character.physicsBody.velocity = ccp(80.f, clampf(character.physicsBody.velocity.y, -MAXFLOAT, 200.f));
            character.physicsBody.velocity = ccp(100.f,0.f);
            
            [super update:delta];
        }
        @catch(NSException* ex)
        {
            
        }
    }
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair character:(CCSprite*)character level:(CCNode*)level {
    [self gameOver];
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair character:(CCNode *)character goal:(CCNode *)goal {
    [goal removeFromParent];
    distance+=50;
    _scoreLabel.string = [NSString stringWithFormat:@"%d", distance];
    return TRUE;
}


@end

