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
#import "Wood.h"
#import "PopupAlert.h"

#define ARC4RANDOM_MAX      0x100000000
static NSString * const kFirstLevel = @"Level1";
static NSString *selectedLevel = @"Level1";
static int levelNum = 0;
static int levelSpeed = 0;
static int enemyInterval = 0;
static int woodTypeCount = 0;
static int woodInterval = 0;
static int levelGoal = 0;

@implementation GameMechanics
{
    //variable representing different scene component
    CCSprite            *_character;
    CCNode              *_setupNode;//level dependent
    CCPhysicsNode       *_staticPhyNode;
    CCPhysicsNode       *_movingNode;
    CCNode              *_contentNode;
    CCNode              *_startTool;
    //CCNode              *_startStation;
    CCNode              *_prevTool;
    CCNode              *_dragTool;
    CCNode              *_weaponPullbackNode;
    CCNode              *_weaponBottomPullBack;
    CCNode              *_mouseJointNode;
    CCPhysicsJoint      *_mouseJoint;
    CCNode              *_weapon;
    
    CCNode              *_cloudNode;
    CCNode              *_cloud1;
    CCNode              *_cloud2;
    
    CCNode              *_bgNode;
    CCNode              *_bg1;
    CCNode              *_bg2;
    //CCButton            *_pauseButton;
    CCLabelTTF          *_scoreLabel;
    CCLabelTTF          *_levelNum;
    CCLabelTTF          *_curScore;
    CCLabelTTF          *_bestScore;
    NSArray             *_clouds;
    NSArray             *_bgs;
    
    
    NSTimeInterval      _sinceTouch;
    NSMutableArray      *_enemies;
    //array of tools used to build the road for Woodie
    NSMutableArray      *_tools;
    //array of floating tools unused
    NSMutableArray      *_floatingTools;
    NSMutableArray      *_weapons;
    BOOL                _gameOver;
    BOOL                _danger;
    int                 _distance;
    int                 _toolCount;
    BOOL                dragTool;
    BOOL                dragWeapon;
    float               _timeSinceEnemy;
    float               _timeSinceWood;
    float               _timeSinceAppear;
    Level               *_loadedLevel;

}

#pragma mark - Node Lifecycle

- (void)didLoadFromCCB {
    CCLOG(@"bp3");
    self.userInteractionEnabled = TRUE;
    //The delegate object that you want to respond to collisions for the collision behavior.
    //_staticPhyNode.collisionDelegate = self;
    _movingNode.collisionDelegate = self;
    
    //_loadedLevelSetting = (LevelSetting *) [CCBReader load:selectedLevelSetting owner:self];
    
    _loadedLevel = (Level *) [CCBReader load:selectedLevel owner:self];
    [_setupNode addChild:_loadedLevel];
    //[_movingNode addChild:_loadedLevel];
    levelSpeed = _loadedLevel.levelSpeed;
    enemyInterval = _loadedLevel.enemyInterval;
    woodTypeCount = _loadedLevel.woodTypeCount;
    woodInterval = _loadedLevel.woodInterval;
    levelNum = _loadedLevel.levelNum;
    levelGoal = _loadedLevel.levelGoal;
    CCLOG(@"bp4");
    _timeSinceEnemy = 0.0f;
    _timeSinceWood = 0.0f;
    _timeSinceAppear = 0.0f;
    //_staticPhyNode.debugDraw = TRUE;
    //_physicsNode.debugDraw = TRUE;
    _clouds = @[_cloud1, _cloud2];
    _bgs = @[_bg1, _bg2];
    _enemies = [NSMutableArray array];
    _tools = [NSMutableArray array];
    _floatingTools = [NSMutableArray array];
    _weapons = [NSMutableArray array];
    _distance = 0;
    _toolCount = 0;
    _scoreLabel.visible = true;
    CCLOG(@"bp5");
    // nothing shall collide with our invisible nodes
    _weaponPullbackNode.physicsBody.collisionMask = @[];
    _weaponBottomPullBack.physicsBody.collisionMask = @[];
    _prevTool = _startTool;
    //CCLOG(@"PREV TOOL LOC %f, %f", _prevTool.position.x, _prevTool.position.y);
    _character.physicsBody.sensor = YES;
    [self addWood];
    CCLOG(@"bp6");
    [self addEnemy];
}

#pragma mark - Touch Handling
// called on every touch in this scene
- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    if (!_gameOver) {
        _sinceTouch = 0.f;
        
        @try
        {
            CGPoint touchLocation = [touch locationInNode:self];
            //firts check if weapon is dragged
            if (CGRectContainsPoint([_weapon boundingBox], touchLocation))
            {
                dragWeapon = TRUE;
                //CCLOG(@"DRAG WEAPON");
                // move the mouseJointNode to the touch position
                _mouseJointNode.position = touchLocation;
                
                // setup a spring joint between the mouseJointNode and the catapultArm
                _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_weapon.physicsBody anchorA:ccp(0, 0) anchorB:ccp(45.50, 54.50) restLength:0.f stiffness:3000.f damping:150.f];
            }
            else{
                CCLOG(@"TOUCH LOC %f %f", touchLocation.x, touchLocation.y);
                CGPoint worldPosition = [self convertToWorldSpace:touchLocation];
                CGPoint screenPosition = [_contentNode convertToNodeSpace:worldPosition];
                CCLOG(@"TOUCH SCREEN LOC %f %f", screenPosition.x, screenPosition.y);
                //loop to check if any tool(wood) dragged
                for (CCNode *tool in _floatingTools)
                {
                    if (CGRectContainsPoint([tool boundingBox], screenPosition))
                    {
                        CCLOG(@"DRAG DETECTED");
                        dragTool = TRUE;
                        _dragTool = tool;
                        _dragTool.position = touchLocation;
                        break;
                    }
                }
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
    CGPoint worldPosition = [self convertToWorldSpace:touchLocation];
    CGPoint screenPosition = [_contentNode convertToNodeSpace:worldPosition];
    if(dragTool)
        _dragTool.position = screenPosition;
    else if(dragWeapon)
        _mouseJointNode.position = touchLocation;
}

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    
    if(dragTool){
        //CCLOG(@"PLACE WOOD");
        //CGPoint touchLocation = [touch locationInNode:self];
        [self placeTool];
        //[self releaseTool];
        dragTool = FALSE;
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
        //[self releaseTool];
        dragTool = FALSE;
    }
    if(dragWeapon){
        //CCLOG(@"MOVE WEAPON");
        //_weapon.physicsBody.velocity =
        //[_weapon.physicsBody applyImpulse:ccp(0, 400.f)];
        [self applyWeapon];
        [self releaseWeapon];
    }
    
}


#pragma mark - Release Dragged Weapon
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
    //CGPoint worldPosition = [self convertToWorldSpace:_dragTool.position];
    //CGPoint screenPosition = [_movingNode convertToNodeSpace:worldPosition];
    //CCLOG(@"ready wood screen pos %f %f", screenPosition.x, screenPosition.y);
    //CCLOG(@"prev wood pos %f %f", _prevTool.position.x, _prevTool.position.y);
    //Wood* wood= (Wood*)[CCBReader load:@"Wood"];
    if(CGRectContainsPoint([_prevTool boundingBox], _dragTool.position))
    {
        //CCLOG(@"INSIDE BOUNDING BOX");
        _dragTool.position = ccp(_prevTool.position.x+(_prevTool.contentSize.width/2)+(_dragTool.contentSize.width/2), _prevTool.position.y);
        //[_contentNode addChild:wood];
        //[_contentNode removeChild:_dragTool];
        [_tools addObject:_dragTool];
        _dragTool.physicsBody.collisionMask = @[];
        [_floatingTools removeObject:_dragTool];
        _prevTool = _dragTool;
        
        NSString *soundFilePath = [NSString stringWithFormat:@"%@/Blop.mp3",
                                   [[NSBundle mainBundle] resourcePath]];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL
                                                                       error:nil];
        player.numberOfLoops = -1; //Infinite
        
        [player play];
    }
    else{
        _dragTool.physicsBody.affectedByGravity = TRUE;
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

#pragma mark - Enemy Spawning
- (void)addEnemy
{
    NSString *curTypeString = [NSString stringWithFormat:@"Enemy%d", levelNum];
    CCNode *enemy = (CCNode *)[CCBReader load:curTypeString];
    enemy.physicsBody.sensor = YES;
    enemy.position = [self getRandomPosition:TRUE];
    [_contentNode addChild:enemy];
    [_enemies addObject:enemy];
}

#pragma mark - Tool Spawning
- (void)addWood
{
    int curType = arc4random_uniform(woodTypeCount)+1;
    NSString *curTypeString = [NSString stringWithFormat:@"Wood%d", curType];
    CCNode *wood = (CCNode *)[CCBReader load: curTypeString];
    wood.physicsBody.sensor = YES;
    wood.position = [self getRandomPosition:FALSE];
    [_contentNode addChild:wood];
    [_floatingTools addObject:wood];
}

- (CGPoint) getRandomPosition: (BOOL) staticY
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    //CCLOG(@"screen width is %f", screenWidth);
    CGFloat randomX = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat randomY = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat startX = 100.f;
    CGFloat endX = screenWidth;
    CGFloat startY = 10.f;
    CGFloat rangeY = screenHeight*0.15;
    if(staticY){
        CGPoint worldPosition = [self convertToWorldSpace:ccp(startX+randomX*(endX-startX), screenHeight*0.08)];
        //CCLOG(@"random position is %f %f", startX+randomX*(endX-startX), startY+randomY*rangeY);
        CGPoint screenPosition = [_contentNode convertToNodeSpace:worldPosition];
        return screenPosition;
    }
    else {
        CGPoint worldPosition = [self convertToWorldSpace:ccp(startX+randomX*(endX-startX), startY+randomY*rangeY)];
        //CCLOG(@"random position is %f %f", startX+randomX*(endX-startX), startY+randomY*rangeY);
        CGPoint screenPosition = [_contentNode convertToNodeSpace:worldPosition];
        return screenPosition;
    }
    
}

#pragma mark - Game Actions

- (void)gameOver:(int)status {
    if (!_gameOver) {
        CCLOG(@"GAME OVER");
        _gameOver = TRUE;
        PopupAlert *popup;
        if(status==0){
            CCLOG(@"DROWNED");
            popup = (PopupAlert *)[CCBReader load:@"DrownedWindow" owner:self];
        }
        else if(status==1){
            CCLOG(@"KILLED");
            popup = (PopupAlert *)[CCBReader load:@"KilledWindow" owner:self];
        }else{
            CCLOG(@"PASSED");
            popup = (PopupAlert *)[CCBReader load:@"PassWindow" owner:self];
            
        }
        popup.positionType = CCPositionTypeNormalized;
        popup.position = ccp(0.5, 0.5);
        _levelNum.string = [NSString stringWithFormat:@"%d", levelNum];
        _curScore.string = [NSString stringWithFormat:@"%d", _distance];
        _bestScore.string = [NSString stringWithFormat:@"%d", _distance];
        [self addChild:popup];
        //pop up window
    }
}

- (void)pause {
    CCLOG(@"Pause");
    //comes with FB check later
    _character.physicsBody.velocity = ccp(0.0f, 0.0f);
    _character.physicsBody.allowsRotation = FALSE;
    [_character stopAllActions];
}

- (void) getInDanger {
    if(!_danger) {
        _danger = TRUE;
        _character.physicsBody.allowsRotation = TRUE;
        _character.physicsBody.affectedByGravity = TRUE;
        //_character.physicsBody.velocity = ccp(0.0f, 0.0f);
        //_character.rotation = 90.f;
        //_character.physicsBody.allowsRotation = FALSE;
        //_character.physicsBody.allowsRotation = FALSE;
        //[_character stopAllActions];
        //CGPoint launchDirection = ccp(0, -1);
        //CGPoint force = ccpMult(launchDirection, 400);
        //[_character.physicsBody applyForce:force];
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
- (void)update:(CCTime)delta
{
    _sinceTouch += delta;
    //CCLOG(@"HERO SPEED IS %f", _character.physicsBody.velocity.x);
    //calc and display current distance conquered
    _distance+=delta*_character.physicsBody.velocity.x*10;
    //CCLOG(@"distance is %d", _distance);
    _scoreLabel.string = [NSString stringWithFormat:@"%d", _distance];
    //CCLOG(@"movingnode width is %f", _movingNode.contentSize.width);
    //screen view move in the same pace as the main character
    _movingNode.position = ccp(_movingNode.position.x - (_character.physicsBody.velocity.x * delta), _movingNode.position.y);
    _cloudNode.position = ccp(_cloudNode.position.x - ((_character.physicsBody.velocity.x)*delta), _cloudNode.position.y);
    _bgNode.position = ccp(_bgNode.position.x - ((_character.physicsBody.velocity.x/2)*delta), _bgNode.position.y);
    //_startStation.position = ccp(_startStation.position.x - (_character.physicsBody.velocity.x * delta), _startStation.position.y);
    
    // loop the clouds
    for (CCNode *cloud in _clouds) {
        // get the world position of the cloud
        CGPoint cloudWorldPosition = [_cloudNode convertToWorldSpace:cloud.position];
        // get the screen position of the cloud
        CGPoint cloudScreenPosition = [self convertToNodeSpace:cloudWorldPosition];
        
        // if the left corner is one complete width off the screen,
        // move it to the right
        if (cloudScreenPosition.x <= (-1 * cloud.contentSize.width * cloud.scaleX)) {
            cloud.position = ccp(cloud.position.x+2*cloud.contentSize.width*cloud.scaleX, cloud.position.y);
        }
    }
    
    // loop the clouds
    for (CCNode *bg in _bgs) {
        // get the world position of the cloud
        CGPoint bgWorldPosition = [_bgNode convertToWorldSpace:bg.position];
        // get the screen position of the cloud
        CGPoint bgScreenPosition = [self convertToNodeSpace:bgWorldPosition];
        
        // if the left corner is one complete width off the screen,
        // move it to the right
        if (bgScreenPosition.x <= (-1 * bg.contentSize.width * bg.scaleX)) {
            bg.position = ccp(bg.position.x+2*bg.contentSize.width*bg.scaleX, bg.position.y);
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
    
    for (CCNode *tool in _floatingTools) {
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
        
        [toolToRemove removeFromParent];
        if([_tools containsObject:toolToRemove]){
            [_tools removeObject:toolToRemove];
            CCLOG(@"REMOVE TOOL");
        }
        else{
            [_floatingTools removeObject:toolToRemove];
            CCLOG(@"REMOVE FLOATING TOOL");
        }
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
    
    if (!_gameOver && !_danger)
    {
        //CCLOG(@"NOT GAME OVER and NO DANGER");
        @try
        {
            if(_distance > levelGoal){
                [self gameOver:2];
            }
            else if(_character.position.x > (_prevTool.position.x + _prevTool.contentSize.width/2 + 10.f))
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
            else {
                _character.physicsBody.velocity = ccp(levelSpeed, 0);
                //Increment the time since the last obstacle was added
                _timeSinceEnemy += delta;
                _timeSinceWood += delta;
                _timeSinceAppear +=  delta;
                //CCLOG(@"time since safe step is %f", _timeSinceSafeStep);
                
                if (_timeSinceEnemy > (double)enemyInterval)
                {
                    //Add a new enemy
                    [self addEnemy];
                    //Then reset the timer
                    _timeSinceEnemy = 0.0f;
                
                }
                if (_timeSinceWood > (double)woodInterval)
                {
                    //Add a new enemy
                    [self addWood];
                    //Then reset the timer
                    _timeSinceWood = 0.0f;
                    _timeSinceAppear = 0.0f;
                    
                }
                if(_timeSinceAppear > (double)woodInterval*2){
                    if(_floatingTools != nil && [_floatingTools count] > 0) {
                        CCNode *wood = [_floatingTools firstObject];
                        [_contentNode removeChild:wood];
                        //[_movingNode addChild:shark];
                        //[_floatingWoodNode removeChild:wood];
                        [_floatingTools removeObject:wood];
                    }
                }
                /*
                if ([_floatingTools count]<=5)
                {
                    [self addWood];
                }
                if ([_floatingTools count]>8)
                {
                    [self removeFloatingWood];
                }*/
            }
            
        }
        @catch(NSException* ex)
        {
            
            }
    }
    else if(!_gameOver){
        //the character is now in danger status
        if(_character.position.y<30.f)
        {
            [self gameOver:0];
        }
    }
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero enemy:(CCNode*)enemy {
    CCLOG(@"EATEN");
    //implement effect of killed by enemies
    [self gameOver:1];
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

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite *)hero tool:(CCSprite*)tool {
    _toolCount += 1;
    CCLOG(@"SAFE %d", _toolCount);
    //[self showScore];
    return TRUE;
}

- (void)toolDestroyed:(CCSprite *)tool {
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"WoodEaten"];
    // place the particle effect on the tool position
    explosion.position = tool.position;
    // add the particle effect to the same node the tool is on
    [tool.parent addChild:explosion];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = YES;
    //different strategies for tools in or not in _tools!!!!!!!!!!!!!!!!!
    if([_tools containsObject:tool]){
        [_tools removeObject:tool];
        _prevTool = [_tools lastObject];
    }
    [tool removeFromParent];
    
}
- (void)enemyKilled:(CCNode *)enemy {
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"EnemyKilled"];
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

#pragma mark - Level completion

- (void)loadNextLevel {
    CCLOG(@"next level");
    
    selectedLevel = _loadedLevel.nextLevelName;
    
    CCScene *nextScene = nil;
    CCLOG(@"bp1");
    if (selectedLevel) {
        nextScene = [CCBReader loadAsScene:@"GameMechanics"];
    } else {
        selectedLevel = kFirstLevel;
        nextScene = [CCBReader loadAsScene:@"MainScene"];
    }
    CCLOG(@"bp2");
    CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    [[CCDirector sharedDirector] presentScene:nextScene withTransition:transition];
}


-(void)backToHome {
    CCScene *scene = [CCBReader loadAsScene:@"MainScene"];
    //[[CCDirector sharedDirector] replaceScene:scene];
    CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    [[CCDirector sharedDirector] presentScene:scene withTransition:transition];
}


@end
