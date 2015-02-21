//
//  PlayerAndTargetView.h
//  heal drudge
//
//  Created by david on 1/24/15.
//  Copyright (c) 2015 Combobulated Software. All rights reserved.
//

#import "PocketHealer.h"

#import <UIKit/UIKit.h>

@class Entity;

typedef void(^EntityTouchedBlock)(Entity *);

@interface PlayerAndTargetView : UIView
{
    CGRect _lastDrawnRect;
}

@property (nonatomic,copy) EntityTouchedBlock entityTouchedHandler;
@property (readonly) CGPoint playerOrigin;

@property Entity *player;
@property Entity *target;

@end
