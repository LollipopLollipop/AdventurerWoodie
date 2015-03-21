#import "MainScene.h"

@implementation MainScene

- (void)play {
    CCScene *gameplayScene = [CCBReader loadAsScene:@"GameScene"];
    [[CCDirector sharedDirector] replaceScene:gameplayScene];
}

@end
