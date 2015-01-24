//
//  Raid.h
//  heal drudge
//
//  Created by david on 1/2/15.
//  Copyright (c) 2015 Combobulated Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Player;

@interface Raid : NSObject

+ (Raid *)randomRaid;
+ (Raid *)randomRaidWithGygiasTheDiscPriest:(Player **)outGygias;

@property (strong,retain) NSArray *players;
@property (nonatomic,readonly) NSArray *tankPlayers;
@property (nonatomic,readonly) NSArray *meleePlayers;
@property (nonatomic,readonly) NSArray *rangePlayers;
@property (nonatomic,readonly) NSArray *healers;
@property (nonatomic,readonly) NSArray *dpsPlayers;
@end
