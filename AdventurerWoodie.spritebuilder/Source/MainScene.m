#import "MainScene.h"

@implementation MainScene

- (void)play {
    CCScene *gameplayScene = [CCBReader loadAsScene:@"Level1"];
    [[CCDirector sharedDirector] replaceScene:gameplayScene];
    //CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    //[[CCDirector sharedDirector] presentScene:gameplayScene withTransition:transition];
}

@end
