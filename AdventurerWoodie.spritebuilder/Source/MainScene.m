#import "MainScene.h"

@implementation MainScene

- (void)play {
    CCScene *gameplayScene = [CCBReader loadAsScene:@"GameMechanics"];
    [[CCDirector sharedDirector] replaceScene:gameplayScene];
    //CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    //[[CCDirector sharedDirector] presentScene:gameplayScene withTransition:transition];
}

@end
