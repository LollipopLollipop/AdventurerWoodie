//
//  GameMechanics.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 3/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "GameMechanics.h"
#import "WoodieWalkRight.h"
#import "Wood.h"

@implementation GameMechanics
- (void)initialize
{
    _character = (WoodieWalkRight*)[CCBReader load:@"WoodieWalkRight"];
    _character.position = ccp(_startStation.position.x-20, _startStation.position.y+80);
    //[_woodContainer addChild:character];
    _rearWave1 = (Wave*)[CCBReader load:@"Wave"];
    _rearWave1.position = ccp(85, 155);
    _rearWave2 = (Wave*)[CCBReader load:@"Wave"];
    _rearWave2.position = ccp(1045, 155);
    _frontWave1 = (WaveLightBlue*)[CCBReader load:@"WaveLightBlue"];
    _frontWave1.position = ccp(85, 155);
    _frontWave2 = (WaveLightBlue*)[CCBReader load:@"WaveLightBlue"];
    _frontWave2.position = ccp(1045, 155);
    [_physicsNode addChild:_character];
    [_physicsNode addChild:_rearWave1];
    [_physicsNode addChild:_rearWave2];
    [_physicsNode addChild:_frontWave1];
    [_physicsNode addChild:_frontWave2];
    [self addObstacle];
    _timeSinceObstacle = 0.0f;
}

-(void)update:(CCTime)delta
{
    //Increment the time since the last obstacle was added
    _timeSinceObstacle += delta;
    
    //Check to see if two seconds have passed
    if (_timeSinceObstacle > 2.0f)
    {
        //Add a new obstacle
        [self addObstacle];
        //Then reset the timer
        _timeSinceObstacle = 0.0f;
        
    }
}

- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    
    CGPoint touchLocation = [touch locationInNode:self];
    // this will get called every time the player touches the screen
    [self placeWood:touchLocation];
    
}
@end
