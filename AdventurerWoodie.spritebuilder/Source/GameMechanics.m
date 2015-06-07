//
//  GameMechanics.m
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 3/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "GameMechanics.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#include <stdlib.h>
#import "PopupAlert.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "Cocos2d.h"


#define ARC4RANDOM_MAX      0x100000000
static NSString * const kFirstLevel = @"Level1";
static NSString *selectedLevel = @"Level2";
static int levelNum = 0;
static int levelSpeed = 0;
static int enemyInterval = 0;
static int woodTypeCount = 0;
static int woodInterval = 0;
static int levelGoal = 0;
static CGFloat screenWidth = 0.0f;
static CGFloat screenHeight = 0.0f;
static float longPressThreshold = 0.5f;


@implementation GameMechanics
{
    //variable representing different scene component
    CCSprite            *_character;
    CCNode              *_setupNode;//level dependent
    CCPhysicsNode       *_staticPhyNode;
    CCPhysicsNode       *_movingNode;
    CCNode              *_contentNode;//to add woods and enemies
    CCNode              *_startTool;
    CCNode              *_prevTool;//to track the latest tool added
    CCNode              *_dragTool;//track the current wood being dragged
    CCNode              *_weaponPullbackNode;
    CCNode              *_weaponBottomPullBack;
    CCNode              *_mouseJointNode;
    CCPhysicsJoint      *_mouseJoint;//nodes used in weapon dragging
    CCNode              *_weapon;
    
    CCNode              *_cloudNode;
    CCNode              *_cloud1;
    CCNode              *_cloud2;
    
    CCNode              *_bgNode;
    CCNode              *_bg1;
    CCNode              *_bg2;
    //info to show to player
    CCLabelTTF          *_scoreLabel;
    CCLabelTTF          *_levelNum;
    CCLabelTTF          *_curScore;
    CCLabelTTF          *_bestScore;
    CCLabelTTF          *_passMsg;
    //button for game status control
    CCButton            *_pauseBtn;
    CCButton            *_resumeBtn;
    //array used for bg looping
    NSArray             *_clouds;
    NSArray             *_bgs;
    
    
    NSTimeInterval      _sinceTouch;
    //dynamic arrays to hold obj added to _contentNode, clear when necessary
    NSMutableArray      *_enemies;
    //array of tools used to build the road for Woodie
    NSMutableArray      *_pathWoods;
    //array of floating tools unused
    NSMutableArray      *_floatingWoods;
    NSMutableArray      *_weapons;
    //bool values to monitor game/character status
    BOOL                _gameOver;
    BOOL                _falling;
    BOOL                _stop;
    BOOL                _safe;
    BOOL                _jumping;
    int                 _distance;
    int                 _safeCount;
    int                 _apartCount;
    //bool values to distinguish what is being dragged
    BOOL                dragTool;
    BOOL                dragWeapon;
    //timer thresholds
    float               _timeSinceEnemy;
    float               _timeSinceWood;
    float               _timeSincePass;
    float               _timeSinceAppear;
    float               _timeSinceStation;
    float               _timeSinceJump;
    float               _jumpDegree;

    Level               *_loadedLevel;

}

#pragma mark - Node Lifecycle

- (void)didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
    //The delegate object that you want to respond to collisions for the collision behavior.
    //_staticPhyNode.collisionDelegate = self;
    _movingNode.collisionDelegate = self;
    
    _loadedLevel = (Level *) [CCBReader load:selectedLevel owner:self];
    [_setupNode addChild:_loadedLevel];
    levelSpeed = _loadedLevel.levelSpeed;
    enemyInterval = _loadedLevel.enemyInterval;
    woodTypeCount = _loadedLevel.woodTypeCount;
    woodInterval = _loadedLevel.woodInterval;
    levelNum = _loadedLevel.levelNum;
    levelGoal = _loadedLevel.levelGoal;
    
    //var init
    _timeSinceEnemy = 0.0f;
    _timeSinceWood = 0.0f;
    _timeSinceAppear = 0.0f;
    _timeSincePass = 0.0f;
    _timeSinceStation = 0.0f;
    _sinceTouch = 0.0f;
    _jumpDegree = 0.0f;
    _timeSinceJump = 0.0f;
    //_staticPhyNode.debugDraw = TRUE;
    //_physicsNode.debugDraw = TRUE;
    _clouds = @[_cloud1, _cloud2];
    _bgs = @[_bg1, _bg2];
    _enemies = [NSMutableArray array];
    _pathWoods = [NSMutableArray array];
    _floatingWoods = [NSMutableArray array];
    _weapons = [NSMutableArray array];
    _distance = 0;
    _apartCount = 0;
    _safeCount = 0;
    _scoreLabel.visible = TRUE;
    _passMsg.visible = FALSE;
    [_pathWoods addObject:_startTool];
    _prevTool = _startTool;
    // nothing shall collide with our invisible nodes
    _weaponPullbackNode.physicsBody.collisionMask = @[];
    _weaponBottomPullBack.physicsBody.collisionMask = @[];
    
    _character.physicsBody.sensor = YES;
    [self addWood];
    [self addEnemy];
    _gameOver = FALSE;
    _falling = FALSE;
    _stop = FALSE;
    _safe = TRUE;
    _jumping = FALSE;
    
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenWidth = screenRect.size.width;
    screenHeight = screenRect.size.height;
    //CCLOG(@"SCREEN SIZE %f", screenWidth);
}

#pragma mark - Touch Handling
// called on every touch in this scene
- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    if (!_gameOver) {
        _sinceTouch = 0.f;
        @try
        {
            CGPoint touchLocation = [touch locationInNode:self];
            //first check if weapon is dragged
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
                //CCLOG(@"TOUCH LOC %f %f", touchLocation.x, touchLocation.y);
                //convert to _contentNode coordinates
                CGPoint worldPosition = [self convertToWorldSpace:touchLocation];
                CGPoint screenPosition = [_contentNode convertToNodeSpace:worldPosition];
                //CCLOG(@"TOUCH SCREEN LOC %f %f", screenPosition.x, screenPosition.y);
                //loop to check if any tool(wood) dragged
                for (CCNode *tool in _floatingWoods)
                {
                    if (CGRectContainsPoint([tool boundingBox], screenPosition))
                    {
                        //CCLOG(@"DRAG DETECTED");
                        dragTool = TRUE;
                        _dragTool = tool;//update _dragTool
                        //_dragTool.position = screenPosition;
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
    //clear sinceTouch timer once touch moves
    _sinceTouch = 0.0f;
    // whenever touches move, update the position of the mouseJointNode to the touch position
    CGPoint touchLocation = [touch locationInNode:self];
    CGPoint worldPosition = [self convertToWorldSpace:touchLocation];
    CGPoint screenPosition = [_contentNode convertToNodeSpace:worldPosition];
    //handling two different coordinates
    if(dragTool)
        _dragTool.position = screenPosition;
    else if(dragWeapon)
        _mouseJointNode.position = touchLocation;
}

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    //CCLOG(@"SINCE TOUCH %f", _sinceTouch);
    if(_sinceTouch > longPressThreshold){
        //[self jumpWoodie:_sinceTouch-longPressThreshold];
        _jumpDegree = _sinceTouch-longPressThreshold;
        [self jumpWoodie];
        _sinceTouch = 0.0f;
    }
    else{
        if(dragTool){
            [self placeTool];
            dragTool = FALSE;
        }
        if(dragWeapon){
            [self applyWeapon];
            [self releaseWeapon];
        }
    }
}

- (void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    //CCLOG(@"SINCE TOUCH %f", _sinceTouch);
    if(_sinceTouch > longPressThreshold){
        //[self jumpWoodie:_sinceTouch-longPressThreshold];
        _jumpDegree = _sinceTouch-longPressThreshold;
        [self jumpWoodie];
        _sinceTouch = 0.0f;
    }
    else{
        if(dragTool){
            [self placeTool];
            dragTool = FALSE;
        }
        if(dragWeapon){
            [self applyWeapon];
            [self releaseWeapon];
        }
    }
    
}

#pragma mark - Jump character
- (void) jumpWoodie{
    if(levelNum >=3){
    //CCLOG(@"JUMP TRIGGERED");
    //trigger jumping animation
    [_character.animationManager runAnimationsForSequenceNamed:@"JumpWoodie"];
    _jumping = TRUE;
    _timeSinceJump = 0.0;
    CCActionJumpTo *jumpTo = [CCActionJumpTo actionWithDuration:1.f position:ccp(_character.position.x+_jumpDegree*100, _character.position.y) height:100*_jumpDegree jumps:1];
    
    [_character runAction: jumpTo];
    _character.physicsBody.sensor = YES;
    }
    
}

#pragma mark - Release Dragged Weapon
- (void)releaseWeapon {
    if (_mouseJoint != nil) {
        // releases the joint and lets the weapon back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        _weapon.position = ccp(500,250);
        dragWeapon = FALSE;
    }
}

#pragma mark - Apply Dragged Obj
- (void)placeTool
{
    CCLOG(@"START PLACE TOOL");
    if ( [ _contentNode.children indexOfObject:_dragTool ] == NSNotFound ) {
        
        // you can add the code here
        CCLOG(@"DRAG TOOL IS NO LONGER IN CONTENT NODE...TERMINATE");
        return;
    }
    
    if(CGRectContainsPoint([_prevTool boundingBox], _dragTool.position))
    {
        CCLOG(@"INSIDE BOUNDING BOX PLACE TOOL STARTS");
        //woods used to build path for Mr.Woodie would no longer be eaten by enemies
        
        
        _dragTool.physicsBody.sensor = TRUE;
        _dragTool.physicsBody.collisionMask = @[@"hero"];
        CCLOG(@"CLEAR COLLISION MASK");
        _dragTool.position = ccp(_prevTool.position.x+(_prevTool.contentSize.width), _prevTool.position.y);
        //update latest wood
        if(_prevTool == nil){
            CCLOG(@"YES, PREV TOOL IS NIL");
        }
        CCLOG(@"BEFORE ADD THERE IS %lu PATH WOODS", (unsigned long)[_pathWoods count]);
        _prevTool = _dragTool;
        CCLOG(@"UPDATE PREV TOOL");
        [_pathWoods addObject:_dragTool];
        [_floatingWoods removeObject:_dragTool];
        CCLOG(@"AFTER ADD THERE IS %lu PATH WOODS", (unsigned long)[_pathWoods count]);
        CCLOG(@"UPDTAE WOODS ARRAY");
        [self configureSystemSound:0];
        [self playSystemSound];
    }
    else{
        //naturally fall if not able to connect to prevTool
        _dragTool.physicsBody.affectedByGravity = TRUE;
    }
    
}

- (void)applyWeapon
{
    CGPoint worldPosition = [self convertToWorldSpace:_weapon.position];
    CGPoint screenPosition = [_movingNode convertToNodeSpace:worldPosition];
    CCNode* invisibleWeapon= (CCNode*)[CCBReader load:@"Weapon"];
    invisibleWeapon.visible = FALSE;
    invisibleWeapon.physicsBody.sensor = YES;
    invisibleWeapon.position = screenPosition;
    [_contentNode addChild:invisibleWeapon];
    [_weapons addObject:invisibleWeapon];
}

#pragma mark - Enemy Spawning
- (void)addEnemy
{
    //different enemies for different levels
    NSString *curTypeString = [NSString stringWithFormat:@"Enemy%d", levelNum];
    CCNode *enemy = (CCNode *)[CCBReader load:curTypeString];
    enemy.physicsBody.sensor = YES;
    enemy.position = [self getRandomPosition:1];
    [_contentNode addChild:enemy];
    [_enemies addObject:enemy];
}

#pragma mark - Wood Spawning
- (void)addWood
{
    //with the increasing levels, more wood types to play with
    int curType = arc4random_uniform(woodTypeCount)+1;
    NSString *curTypeString = [NSString stringWithFormat:@"Wood%d", curType];
    CCNode *wood = (CCNode *)[CCBReader load: curTypeString];
    wood.physicsBody.sensor = YES;
    wood.position = [self getRandomPosition:0];
    [_contentNode addChild:wood];
    [_floatingWoods addObject:wood];
}

#pragma mark - Station Spawning
- (void)addStation
{
    //with the increasing levels, more wood types to play with
    int curType = arc4random_uniform(4)+1;
    NSString *curTypeString = [NSString stringWithFormat:@"Station%d", curType];
    CCNode *station = (CCNode *)[CCBReader load: curTypeString];
    station.physicsBody.sensor = YES;
    station.position = [self getRandomPosition:2];
    [_contentNode addChild:station];
    [_pathWoods addObject:station];
}

// 0-wood, 1-enemy, 2-station
- (CGPoint) getRandomPosition: (int) objType
{
    //CCLOG(@"screen width is %f", screenWidth);
    CGFloat randomX = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat randomY = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat startX = 200.f;
    CGFloat endX = screenWidth;
    CGFloat startY = 10.f;
    CGFloat rangeY = screenHeight*0.15;
    if(objType==1){
        CGPoint worldPosition = [self convertToWorldSpace:ccp(startX+randomX*(endX-startX), screenHeight*0.08)];
        //CCLOG(@"random position is %f %f", startX+randomX*(endX-startX), startY+randomY*rangeY);
        CGPoint screenPosition = [_contentNode convertToNodeSpace:worldPosition];
        return screenPosition;
    }
    else if(objType==0){
        CGPoint worldPosition = [self convertToWorldSpace:ccp(startX+randomX*(endX-startX), startY+randomY*rangeY)];
        //CCLOG(@"random position is %f %f", startX+randomX*(endX-startX), startY+randomY*rangeY);
        CGPoint screenPosition = [_contentNode convertToNodeSpace:worldPosition];
        return screenPosition;
    }else{
        CGPoint worldPosition = [self convertToWorldSpace:ccp(1.2*screenWidth, 65.f)];
        //CCLOG(@"random position is %f %f", startX+randomX*(endX-startX), startY+randomY*rangeY);
        CGPoint screenPosition = [_contentNode convertToNodeSpace:worldPosition];
        return screenPosition;
    }
    
}

#pragma mark - Game Actions

- (void)gameOver:(int)status {
    
    if (!_gameOver) {
        //CCLOG(@"GAME OVER");
        _gameOver = TRUE;
        _character.physicsBody.velocity = ccp(0.0f, 0.0f);
        [_character stopAllActions];
        
        //pop up different windows according to game over status
        PopupAlert *popup;
        if(status==0){
            //CCLOG(@"DROWNED");
            popup = (PopupAlert *)[CCBReader load:@"DrownedWindow" owner:self];
            [self configureSystemSound:4];
            [self playSystemSound];
        }
        else if(status==1){
            //CCLOG(@"KILLED");
            popup = (PopupAlert *)[CCBReader load:@"KilledWindow" owner:self];
            [self configureSystemSound:3];
            [self playSystemSound];
        }else{
            //CCLOG(@"PASSED");
            popup = (PopupAlert *)[CCBReader load:@"PassWindow" owner:self];
            [self configureSystemSound:5];
            [self playSystemSound];
            
        }
        NSString *levelBestScoreKey = [NSString stringWithFormat:@"BestScore%d", levelNum];
        int levelBestScore = [[NSUserDefaults standardUserDefaults] integerForKey:levelBestScoreKey] ;
        if(_distance > levelBestScore){
            [[NSUserDefaults standardUserDefaults] setInteger: _distance forKey: levelBestScoreKey];
            levelBestScore = _distance;
        }
        
        popup.positionType = CCPositionTypeNormalized;
        popup.position = ccp(0.5, 0.5);
        _levelNum.string = [NSString stringWithFormat:@"%d", levelNum];
        _curScore.string = [NSString stringWithFormat:@"%d", _distance];
        _bestScore.string = [NSString stringWithFormat:@"%d", levelBestScore];
        [self addChild:popup];
        //pop up window
    }
}

//toggle the pause and resume buttons
- (void)pause {
    if(!_stop){
        _stop = TRUE;
        [self configureSystemSound:6];
        [self playSystemSound];
        //CCLOG(@"Pause");
        _character.physicsBody.velocity = ccp(0.0f, 0.0f);
        [_character stopAllActions];
        _pauseBtn.visible = FALSE;
        _resumeBtn.visible = TRUE;
    }
}

-(void)resume{
    if(_stop){
        _stop = FALSE;
        [self configureSystemSound:6];
        [self playSystemSound];
        _pauseBtn.visible = TRUE;
        _resumeBtn.visible = FALSE;
    }
}


- (void)restart {
    [self configureSystemSound:6];
    [self playSystemSound];
    CCScene *scene = [CCBReader loadAsScene:@"GameMechanics"];
    //[[CCDirector sharedDirector] replaceScene:scene];
    CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    [[CCDirector sharedDirector] presentScene:scene withTransition:transition];
    
}

#pragma mark - Update
- (void)update:(CCTime)delta
{
    //timer update
    _sinceTouch += delta;
    _timeSinceStation += delta;
    _timeSinceEnemy += delta;
    _timeSinceWood += delta;
    _timeSinceAppear +=  delta;
    
    if(_distance > levelGoal){
        _timeSincePass += delta;
        if(_timeSincePass<10.f){
            _passMsg.string = [NSString stringWithFormat:@"%d miles completed! Level %d passed!", levelGoal, levelNum];
            _passMsg.visible = TRUE;
        }
        else{
            _passMsg.visible = FALSE;
        }
    }
    
    //calc and display current distance conquered
    _distance+=delta*_character.physicsBody.velocity.x*10;
    //CCLOG(@"distance is %d", _distance);
    _scoreLabel.string = [NSString stringWithFormat:@"%d", _distance];
    
    
    //moving view configurations
    if(!_jumping){
        _movingNode.position = ccp(_movingNode.position.x - (_character.physicsBody.velocity.x * delta), _movingNode.position.y);
    }
    else{
        //CCLOG(@"jumpING %f", _timeSinceJump);
        _timeSinceJump += delta;
        _movingNode.position = ccp(_movingNode.position.x - (100*_jumpDegree * delta), _movingNode.position.y);
        //jump action is fixed to 1 sec
        if(_timeSinceJump>1.f){
            //stop jumping status by timer restriction
            _jumping = FALSE;
            [_character.animationManager runAnimationsForSequenceNamed:@"NewWoodie"];
            _timeSinceJump = 0.0f;
            _character.physicsBody.sensor = TRUE;
        }
    }
    
    //cloud and bg canvas moving at different speed
    _cloudNode.position = ccp(_cloudNode.position.x - ((_character.physicsBody.velocity.x)*delta), _cloudNode.position.y);
    _bgNode.position = ccp(_bgNode.position.x - ((_character.physicsBody.velocity.x/2)*delta), _bgNode.position.y);
    
    
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
    NSMutableArray *offScreenPathTools = nil;
    NSMutableArray *offScreenFloatingTools = nil;
    NSMutableArray *offScreenWeapons = nil;
    
    for (CCNode *enemy in _enemies) {
        CGPoint enemyWorldPosition = [_contentNode convertToWorldSpace:enemy.position];
        CGPoint enemyScreenPosition = [self convertToNodeSpace:enemyWorldPosition];
        if (enemyScreenPosition.x < -enemy.contentSize.width) {
            if (!offScreenEnemies) {
                offScreenEnemies = [NSMutableArray array];
            }
            [offScreenEnemies addObject:enemy];
        }
    }
    
    for (CCNode *enemyToRemove in offScreenEnemies) {
        //CCLOG(@"REMOVE");
        [enemyToRemove removeFromParent];
        [_enemies removeObject:enemyToRemove];
    }
    /*
    for (CCNode *tool in _pathWoods) {
        CGPoint toolWorldPosition = [_contentNode convertToWorldSpace:tool.position];
        CGPoint toolScreenPosition = [self convertToNodeSpace:toolWorldPosition];
        if (toolScreenPosition.x < -tool.contentSize.width) {
            if (!offScreenPathTools) {
                offScreenPathTools = [NSMutableArray array];
            }
            [offScreenPathTools addObject:tool];
        }
    }
    for (CCNode *toolToRemove in offScreenPathTools) {
        //CCLOG(@"REMOVE");
        [toolToRemove removeFromParent];
        [_pathWoods removeObject:toolToRemove];
    }*/
    
    for (CCNode *tool in _floatingWoods) {
        CGPoint toolWorldPosition = [_contentNode convertToWorldSpace:tool.position];
        CGPoint toolScreenPosition = [self convertToNodeSpace:toolWorldPosition];
        if (toolScreenPosition.x < -tool.contentSize.width) {
            if (!offScreenFloatingTools) {
                offScreenFloatingTools = [NSMutableArray array];
            }
            [offScreenFloatingTools addObject:tool];
        }
    }
    
    for (CCNode *toolToRemove in offScreenFloatingTools) {
        
        [toolToRemove removeFromParent];
        [_floatingWoods removeObject:toolToRemove];
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
    
    //_prevTool = [_pathWoods lastObject];
    
    if(_falling || _jumping){
        //in falling or jumping, Mr.Woodie faces the danger of drowning
        if(_character.position.y<30.f)
        {
            if(_distance > levelGoal){
                [self gameOver:2];
            }
            else{
                [self gameOver:0];
            }
            
        }
    }
    else if (!_gameOver && !_stop) //only proceed when not gameover, not falling and not paused and jumping
    {
        //CCLOG(@"NOT GAME OVER and NO DANGER");
        @try
        {
            if(_apartCount >= _safeCount){
                //CCLOG(@"un safe falling!!!!!!!!!!!!");
                _safe = FALSE;
                _falling = TRUE;
                _character.physicsBody.affectedByGravity = TRUE;
                _character.physicsBody.velocity = ccp(0, -200);
            }
            _character.physicsBody.velocity = ccp(levelSpeed, 0);
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
            //remove floating woods continuously some time after a new one spawned
            //woods are continuously removed but not enemies
            if(_timeSinceAppear > (double)woodInterval*2){
                    if(_floatingWoods) {
                        //CCLOG(@"REMOVE FLOATING WOODS");
                        CCNode *wood = [_floatingWoods firstObject];
                        [_contentNode removeChild:wood];
                        [_floatingWoods removeObject:wood];
                    }
            }
            if(levelNum >=3){
                //regularly add new stations
                if(_timeSinceStation > (screenWidth/levelSpeed)*0.5){
                    [self addStation];
                    _timeSinceStation = 0.0f;
                }
            }
        }
        @catch(NSException* ex)
        {
            
        }
    }
    else if(_falling){
        
    }
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite*)hero enemy:(CCNode*)enemy {
    //CCLOG(@"EATEN");
    //implement effect of killed by enemies
    if(_distance > levelGoal){
        [self gameOver:2];
    }
    else{
        [self gameOver:1];
    }
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair tool:(CCSprite *)tool enemy:(CCNode*)enemy {
    //CCLOG(@"Overlap");
    //[self toolDestroyed:tool];
    CCLOG(@"!!!!!!!!!!!!!!!!!TOOL DESTROY START");
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"WoodEaten"];
    // place the particle effect on the tool position
    explosion.position = tool.position;
    // add the particle effect to the same node the tool is on
    [tool.parent addChild:explosion];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = YES;
    CCLOG(@"!!!!!!!!!!!!!!!!!!!!EXPLOSION AUTO REMOVE");
    /*if(tool == _prevTool){
        CCLOG(@"!!!!!!!!!!!!!!!!YES, IT IS THE PREV TOOL");
        [_pathWoods removeObject:tool];
        _prevTool = [_pathWoods lastObject];
    }*/
    CCLOG(@"!!!!!!!!!!!!!!!!!!!!CHECK IF PREV");
    [_floatingWoods removeObject:tool];
    [tool removeFromParent];
    CCLOG(@"!!!!!!!!!!!!!!!!!!!!REMOVE THE TOOL");
    /*if ( [ _contentNode.children indexOfObject:tool ] == NSNotFound ) {
        
        // you can add the code here
        CCLOG(@"YES, TOOL IS NO LONGER IN CONTENT NODE");
    }*/
    return TRUE;
}
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair enemy:(CCNode *)enemy weapon:(CCSprite*)weapon {
    //CCLOG(@"Kill");
    [self enemyKilled:enemy];
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair enemy:(CCNode *)enemy station:(CCSprite*)station {
    //CCLOG(@"Kill");
    [self enemyKilled:enemy];
    return TRUE;
}


-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite *)hero tool:(CCSprite*)tool {
    //_character.physicsBody.affectedByGravity = FALSE;
    _safeCount += 1;
    //CCLOG(@"SAFE %d", _safeCount);
    _safe = TRUE;
    _jumping = FALSE;
    [_character.animationManager runAnimationsForSequenceNamed:@"NewWoodie"];
    _timeSinceJump = 0.0f;
    _character.physicsBody.sensor = TRUE;
    return TRUE;
}


-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair*)pair hero:(CCSprite *)hero station:(CCSprite*)station {
    //_character.physicsBody.affectedByGravity = FALSE;
    _safeCount += 1;
    //_apartCount = 0;
    //CCLOG(@"SAFE STATION %d", _safeCount);
    _safe = TRUE;
    _timeSinceJump = 0.0f;
    _prevTool = station;
    _jumping = FALSE;
    [_character.animationManager runAnimationsForSequenceNamed:@"NewWoodie"];
    _character.physicsBody.sensor = TRUE;
    return TRUE;
}

- (void)ccPhysicsCollisionSeparate:(CCPhysicsCollisionPair*)pair hero:(CCSprite *)hero tool:(CCSprite*)tool {
    _apartCount += 1;
    //CCLOG(@"APART %d", _apartCount);
    if(!_jumping){
        //_apartCount += 1;
        //CCLOG(@"APART %d", _apartCount);
        if(_apartCount >= _safeCount){
            //CCLOG(@"unsafe falling!!!!!!!!!!!!");
            _safe = FALSE;
            _falling = TRUE;
            _character.physicsBody.affectedByGravity = TRUE;
            _character.physicsBody.velocity = ccp(0, -200);
        }
    }else{
        //CCLOG(@"APART DETECTED DURING JUMPING");
    }
    /*
    if(_apartCount >= _safeCount){
        //Mr.Woodie is not stepping onto safe woods
        _safe = FALSE;
        _falling = TRUE;
        _character.physicsBody.affectedByGravity = TRUE;
        
    }*/
    
    
}

- (void)ccPhysicsCollisionSeparate:(CCPhysicsCollisionPair*)pair hero:(CCSprite *)hero station:(CCSprite*)station {
    _apartCount += 1;
    //CCLOG(@"APART STATION %d", _apartCount);
    if(!_jumping){
        //_apartCount += 1;
        //CCLOG(@"APART %d", _apartCount);
        if(_apartCount >= _safeCount){
            //CCLOG(@"unsafe falling!!!!!!!!!!!!");
            _safe = FALSE;
            _falling = TRUE;
            _character.physicsBody.affectedByGravity = TRUE;
            _character.physicsBody.velocity = ccp(0, -200);
        }
    }else{
        //CCLOG(@"APART DETECTED DURING JUMPING");
    }
    
    /*if(_apartCount >= _safeCount){
        //Mr.Woodie is not stepping onto safe woods
        _safe = FALSE;
        _falling = TRUE;
        _character.physicsBody.affectedByGravity = TRUE;
        
    }*/
    
    
}

- (void)toolDestroyed:(CCSprite *)tool {
    /*CCLOG(@"!!!!!!!!!!!!!!!!!TOOL DESTROY START");
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"WoodEaten"];
    // place the particle effect on the tool position
    explosion.position = tool.position;
    // add the particle effect to the same node the tool is on
    [tool.parent addChild:explosion];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = YES;
    CCLOG(@"!!!!!!!!!!!!!!!!!!!!EXPLOSION AUTO REMOVE");
    if(tool == _prevTool){
        [_pathWoods removeObject:tool];
        _prevTool = [_pathWoods lastObject];
    }
    CCLOG(@"!!!!!!!!!!!!!!!!!!!!CHECK IF PREV");
    [_floatingWoods removeObject:tool];
    [tool removeFromParent];
    CCLOG(@"!!!!!!!!!!!!!!!!!!!!REMOVE THE TOOL");*/
    
    
}
- (void)enemyKilled:(CCNode *)enemy {
    [self configureSystemSound:1];
    [self playSystemSound];
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"EnemyKilled"];
    // place the particle effect on the enemy position
    explosion.position = enemy.position;
    // add the particle effect to the same node the enemy is on
    [enemy.parent addChild:explosion];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = YES;
    
    // finally, remove the destroyed enemy
    [enemy removeFromParent];
    [_enemies removeObject:enemy];
}

#pragma mark - Level completion

- (void)loadNextLevel {
    [self configureSystemSound:6];
    [self playSystemSound];
    //CCLOG(@"next level");
    
    selectedLevel = _loadedLevel.nextLevelName;
    
    CCScene *nextScene = nil;
    //CCLOG(@"bp1");
    if (selectedLevel) {
        nextScene = [CCBReader loadAsScene:@"GameMechanics"];
    } else {
        selectedLevel = kFirstLevel;
        nextScene = [CCBReader loadAsScene:@"MainScene"];
    }
    //CCLOG(@"bp2");
    CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    [[CCDirector sharedDirector] presentScene:nextScene withTransition:transition];
}


-(void)backToHome {
    [self configureSystemSound:6];
    [self playSystemSound];
    CCScene *scene = [CCBReader loadAsScene:@"MainScene"];
    //[[CCDirector sharedDirector] replaceScene:scene];
    CCTransition *transition = [CCTransition transitionFadeWithDuration:0.8f];
    [[CCDirector sharedDirector] presentScene:scene withTransition:transition];
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
        //CCLOG(@"enter blop");
        audioPath = [[NSBundle mainBundle] pathForResource:@"Blop" ofType:@"wav"];
    }
    else if(actionType==1){
        audioPath = [[NSBundle mainBundle] pathForResource:@"Stab" ofType:@"wav"];
    }
    else if(actionType==2){
        audioPath = [[NSBundle mainBundle] pathForResource:@"Jump" ofType:@"wav"];
    }
    else if(actionType==3){
        audioPath = [[NSBundle mainBundle] pathForResource:@"Groan" ofType:@"wav"];
    }
    else if(actionType==4){
        audioPath = [[NSBundle mainBundle] pathForResource:@"Water" ofType:@"wav"];
    }
    else if(actionType==5){
        audioPath = [[NSBundle mainBundle] pathForResource:@"Whistling" ofType:@"wav"];
    }
    else{
        audioPath = [[NSBundle mainBundle] pathForResource:@"Button" ofType:@"wav"];
    }
    NSURL *audioURL = [NSURL fileURLWithPath:audioPath];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioURL, &_actionSound);
}

-(void) shareToFacebook {
    /*
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    
    // this should link to FB page for your app or AppStore link if published
    content.contentURL = [NSURL URLWithString:@"https://www.facebook.com/makeschool"];
    // URL of image to be displayed alongside post
    content.imageURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/LollipopLollipop/AdventurerWoodie/master/FBsharingImg.png"];
    // title of post
    content.contentTitle = [NSString stringWithFormat:@"I just completed level %d at Adventure Woodie! Come to join me!", levelNum];
    // description/body of post
    content.contentDescription = @"Check out the crazy adventure with Mr.Woodie.";
    
    [FBSDKShareDialog showFromViewController:[CCDirector sharedDirector]
                                 withContent:content
                                    delegate:nil];*/
    CCLOG(@"SHARING");
    UIImage *img = [UIImage imageNamed:@"FBsharingImg.png"];
          
    FBSDKSharePhoto *screen = [[FBSDKSharePhoto alloc] init];
    screen.image = img;
    screen.userGenerated = YES;
          
    FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
    content.photos = @[screen];
          
    FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
    dialog.fromViewController = [CCDirector sharedDirector];
    [dialog setShareContent:content];
    dialog.mode = FBSDKShareDialogModeShareSheet;
    [dialog show];
}


@end
