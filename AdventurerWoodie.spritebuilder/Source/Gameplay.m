//
//  Gameplay.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 2/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Gameplay.h"


@implementation Gameplay{
    CCPhysicsNode *_physicsNode;
    CCNode *_startWood;
    CGPoint prevWoodLoc;
    //CCNode *prevWood;
    CCNode *_walkingWoodie;
}


// is called when CCB file has completed loading
- (void)didLoadFromCCB {
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    prevWoodLoc = _startWood.position;
}
// called on every touch in this scene
- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    
    
    CGPoint touchLocation = [touch locationInNode:_physicsNode];
    CGRect prevWoodNeighbor;
    prevWoodNeighbor.origin = prevWoodLoc;
    prevWoodNeighbor.size.width = 116;
    prevWoodNeighbor.size.height = 20;
    // start catapult dragging when a touch inside of the catapult arm occurs
    if (CGRectContainsPoint(prevWoodNeighbor, touchLocation))
    {
        [self placeWood];
    }
    
    
}
- (void)placeWood {
    // loads the Penguin.ccb we have set up in Spritebuilder
    CCNode* wood = [CCBReader load:@"Wood"];
    // position the penguin at the bowl of the catapult
    wood.position = ccpAdd(prevWoodLoc, ccp(58, 0));
    prevWoodLoc = wood.position;
    
    // add the penguin to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:wood];
    
    // manually create & apply a force to launch the penguin
    //CGPoint launchDirection = ccp(1, 0);
    //CGPoint force = ccpMult(launchDirecti[penguin.physicsBody applyForce:force];
    self.position = ccp(0, 0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:wood worldBoundary:self.boundingBox];
    [self runAction:follow];
    
}
- (void)update:(CCTime)delta
{
    _walkingWoodie.position = ccp(_walkingWoodie.position.x + 100* delta, _walkingWoodie.position.y);
    // ensure followed object is in visible are when starting
    
}

@end
