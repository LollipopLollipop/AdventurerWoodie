//
//  GameMechanics.h
//  AdventurerWoodie
//
//  Created by Ding ZHAO on 3/21/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCNode.h"
#import "WoodieWalkRight.h"
#import "Wave.h"
#import "Wood.h"
#import "WaveLightBlue.h"


//specify drawing orders of different components at level scenes
typedef NS_ENUM(NSInteger, DrawingOrder) {
    
    DrawingOrderRearGround,
    DrawingOrderTool,
    DrawingOrderHero,
    DrawingOrderEnemy,
    DrawingOrderWeapon,
    DrawingOrderFrontGround
    
};


@interface GameMechanics : CCNode <CCPhysicsCollisionDelegate>
@end
