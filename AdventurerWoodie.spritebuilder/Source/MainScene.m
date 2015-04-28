#import "MainScene.h"
#import "Instructions.h"

@implementation MainScene

- (void)play {
    [self configureSystemSound:0];
    [self playSystemSound];
    CCScene *gameplayScene = [CCBReader loadAsScene:@"GameMechanics"];
    //[[CCDirector sharedDirector] replaceScene:gameplayScene];
    CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    [[CCDirector sharedDirector] presentScene:gameplayScene withTransition:transition];
}

- (void)showInstruction1 {
    [self configureSystemSound:0];
    [self playSystemSound];
    Instructions *insWindow = (Instructions *)[CCBReader load:@"InstructionWindow1" owner:self];
    insWindow.positionType = CCPositionTypeNormalized;
    insWindow.position = ccp(0.5, 0.5);
    [self addChild:insWindow];
}

-(void)showInstruction2 {
    [self configureSystemSound:0];
    [self playSystemSound];
    Instructions *insWindow = (Instructions *)[CCBReader load:@"InstructionWindow2" owner:self];
    insWindow.positionType = CCPositionTypeNormalized;
    insWindow.position = ccp(0.5, 0.5);
    [self addChild:insWindow];
}

-(void)showInstruction3 {
    [self configureSystemSound:0];
    [self playSystemSound];
    Instructions *insWindow = (Instructions *)[CCBReader load:@"InstructionWindow3" owner:self];
    insWindow.positionType = CCPositionTypeNormalized;
    insWindow.position = ccp(0.5, 0.5);
    [self addChild:insWindow];
    
}

-(void)backToHome {
    [self configureSystemSound:0];
    [self playSystemSound];
    CCScene *scene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:scene];
    //CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    //[[CCDirector sharedDirector] presentScene:scene withTransition:transition];
}


- (void)playSystemSound {
    //CCLOG(@"enter play");
    AudioServicesPlaySystemSound(self.actionSound);
    //CCLOG(@"finish play");
}

- (void)configureSystemSound:(int) actionType {
    // This is the simplest way to play a sound.
    // But note with System Sound services you can only use:
    // File Formats (a.k.a. audio containers or extensions): CAF, AIF, WAV
    // Data Formats (a.k.a. audio encoding): linear PCM (such as LEI16) or IMA4
    // Sounds must be 30 sec or less
    // And only one sound plays at a time!
    //CCLOG(@"enter config");
    NSString *audioPath;
    if(actionType==0){
        audioPath = [[NSBundle mainBundle] pathForResource:@"Button" ofType:@"wav"];
    }
    NSURL *audioURL = [NSURL fileURLWithPath:audioPath];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioURL, &_actionSound);
}



@end
