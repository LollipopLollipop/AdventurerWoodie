#import "MainScene.h"
#import "Instructions.h"

@implementation MainScene

- (void)play {
    CCScene *gameplayScene = [CCBReader loadAsScene:@"GameMechanics"];
    //[[CCDirector sharedDirector] replaceScene:gameplayScene];
    CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    [[CCDirector sharedDirector] presentScene:gameplayScene withTransition:transition];
}

- (void)showInstruction1 {
    Instructions *insWindow = (Instructions *)[CCBReader load:@"InstructionWindow1" owner:self];
    insWindow.positionType = CCPositionTypeNormalized;
    insWindow.position = ccp(0.5, 0.5);
    [self addChild:insWindow];
}

-(void)showInstruction2 {
    Instructions *insWindow = (Instructions *)[CCBReader load:@"InstructionWindow2" owner:self];
    insWindow.positionType = CCPositionTypeNormalized;
    insWindow.position = ccp(0.5, 0.5);
    [self addChild:insWindow];
}

-(void)showInstruction3 {
    Instructions *insWindow = (Instructions *)[CCBReader load:@"InstructionWindow3" owner:self];
    insWindow.positionType = CCPositionTypeNormalized;
    insWindow.position = ccp(0.5, 0.5);
    [self addChild:insWindow];
    
}

-(void)backToHome {
    CCScene *scene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:scene];
    //CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    //[[CCDirector sharedDirector] presentScene:scene withTransition:transition];
}

@end
