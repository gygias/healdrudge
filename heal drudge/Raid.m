//
//  Raid.m
//  heal drudge
//
//  Created by david on 1/2/15.
//  Copyright (c) 2015 Combobulated Software. All rights reserved.
//

#import "Raid.h"
#import "Entity.h"
#import "HDClass.h"

#import "ItemLevelAndStatsConverter.h"

@implementation Raid

+ (Raid *)randomRaid
{
    return [self randomRaidWithTanks:2 healerRatio:0.2];
}

+ (Raid *)randomRaidWithTanks:(NSUInteger)tanks healerRatio:(float)healerRatio
{
    NSString *namesPath = [[NSBundle mainBundle] pathForResource:@"Names" ofType:@"plist"];
    NSArray *names = [NSArray arrayWithContentsOfFile:namesPath];
    
    NSMutableArray *players = [NSMutableArray array];
    NSUInteger randomSize = [names count] - arc4random() % 10;
    // XXX
    randomSize = 5;
    NSUInteger nHealers = healerRatio * randomSize;
    NSUInteger idx = 0;
    for ( ; idx < randomSize; idx++ )
    {
        Entity *aPlayer = [Entity new];
        aPlayer.isPlayer = YES;
        aPlayer.name = names[idx];
        aPlayer.averageItemLevelEquipped = @630;
        aPlayer.hdClass = [HDClass randomClass];
        
        if ( idx < tanks )
            aPlayer.hdClass = [HDClass randomTankClass];
        else if ( ( idx >= tanks ) && ( idx - tanks < nHealers ) )
            aPlayer.hdClass = [HDClass randomHealerClass];
        else
            aPlayer.hdClass = [HDClass randomDPSClass];
        
        [ItemLevelAndStatsConverter assignStatsToEntity:aPlayer
                        basedOnAverageEquippedItemLevel:@630];
        [aPlayer initializeSpells];
        
        NSLog(@"added %@",aPlayer);
        
        // cheap ass randomize
        if ( idx == 0 )
            [players addObject:aPlayer];
        else
            [players insertObject:aPlayer atIndex:(arc4random() % 2) == 1 ? 0 : [players count]];
        
    }
    
    Raid *aRaid = [Raid new];
    aRaid.players = players;
    
    return aRaid;
}

+ (Raid *)randomRaidWithStandardDistribution
{
    return [self randomRaidWithTanks:2 healerRatio:.2];
}

+ (Raid *)randomRaidWithGygiasTheDiscPriestAndSlyTheProtPaladin:(Entity **)outGygias
{
    Raid *raid = [self randomRaidWithTanks:0 healerRatio:0];
    
    Entity *gygias = [Entity new];
    gygias.isPlayer = YES;
    gygias.name = @"Gygias";
    gygias.hdClass = [HDClass discPriest];
    
    NSNumber *gygiasIlvl = @670;
    [ItemLevelAndStatsConverter assignStatsToEntity:gygias
                    basedOnAverageEquippedItemLevel:gygiasIlvl];
    [gygias initializeSpells];
    
    Entity *slyeri = [Entity new];
    slyeri.isPlayer = YES;
    slyeri.name = @"Slyeri";
    slyeri.hdClass = [HDClass protPaladin];
    
    NSNumber *slyIlvl = @670;
    [ItemLevelAndStatsConverter assignStatsToEntity:slyeri
                    basedOnAverageEquippedItemLevel:slyIlvl];
    [slyeri initializeSpells];
    
    NSMutableArray *raidCopy = raid.players.mutableCopy;
    __block NSInteger gygiasIdx = -1;
    __block NSInteger slyIdx = -1;
    __block NSInteger someHealerIdx = -1;
    [raidCopy enumerateObjectsUsingBlock:^(Entity *obj, NSUInteger idx, BOOL *stop) {
        if ( [obj.name compare:gygias.name options:NSCaseInsensitiveSearch] == NSOrderedSame )
            gygiasIdx = idx;
        else if ( obj.hdClass.isHealerClass )
            someHealerIdx = idx;
        else if ( [obj.name compare:slyeri.name options:NSCaseInsensitiveSearch] == NSOrderedSame )
            slyIdx = idx;
    }];
    
    if ( slyIdx >= 0 )
    {
        NSLog(@"removing %@",[raidCopy objectAtIndex:slyIdx]);
        [raidCopy removeObjectAtIndex:slyIdx];
    }
    
    slyIdx = raidCopy.count;
    
    NSLog(@"adding %@",slyeri);
    [raidCopy insertObject:slyeri atIndex:slyIdx];
    
    if ( gygiasIdx >= 0 || someHealerIdx >= 0 )
    {
        NSInteger removeIndex = gygiasIdx >= 0 ? gygiasIdx : someHealerIdx;
        NSLog(@"removing %@",[raidCopy objectAtIndex:removeIndex]);
        [raidCopy removeObjectAtIndex:removeIndex];
    }
    
    gygiasIdx = raidCopy.count;
    
    NSLog(@"adding %@",gygias);
    [raidCopy insertObject:gygias atIndex:gygiasIdx];
    if ( raid.players.count >= 20 )
        [raidCopy removeObjectAtIndex: ( ( gygiasIdx >= 0 ? gygiasIdx : someHealerIdx )+ 1 % raid.players.count )];
    
    raid.players = raidCopy;
    
    NSLog(@"%@",raid.players);
    
    if ( outGygias )
        *outGygias = gygias;
    
    return raid;
}

typedef NS_ENUM(NSInteger, EntityRange) {
    AnyRange            = 0,
    MeleeRange          = 1,
    RangeRange          = 2
};

- (NSArray *)tankPlayers
{
    return [self _playersWithRole:TankRole range:MeleeRange];
}

- (NSArray *)meleePlayers
{
    return [self _playersWithRole:DPSRole range:MeleeRange];
}

- (NSArray *)rangePlayers
{
    return [self _playersWithRole:DPSRole range:RangeRange];
}

- (NSArray *)healers
{
    return [self _playersWithRole:HealerRole range:AnyRange];
}

- (NSArray *)dpsPlayers
{
    return [self _playersWithRole:DPSRole range:AnyRange];
}

- (NSArray *)_playersWithRole:(const NSString *)role range:(EntityRange)range
{
    __block NSMutableArray *filteredPlayers = nil;
    [self.players enumerateObjectsUsingBlock:^(Entity *player, NSUInteger idx, BOOL *stop) {
        if ( [player.hdClass hasRole:role] &&
                ( ( range == AnyRange )
                    || ( player.hdClass.isRanged && ( range == RangeRange ) )
                    || ( ! player.hdClass.isRanged && ( range == MeleeRange ) )
             )
            )
        {
            if ( ! filteredPlayers ) filteredPlayers = [NSMutableArray new];
            [filteredPlayers addObject:player];
        }
    }];
    
    return filteredPlayers;
}

- (NSArray *)partyForEntity:(Entity *)entity includingEntity:(BOOL)includingEntity
{
    NSUInteger idx = [self.players indexOfObject:entity];
    if ( idx == NSNotFound )
    {
        NSLog(@"error: %@ not found in raid",entity);
        return nil;
    }
    
    NSUInteger partySize = 5;
    NSUInteger partyNumber = idx / partySize;
    NSMutableArray *players = [NSMutableArray new];
    NSUInteger partyIdx = 0;
    for( ; partyIdx < partySize && partyIdx < self.players.count; partyIdx++ )
    {
        Entity *aPartyPlayer = self.players[partyNumber * partySize + partyIdx];
        if ( ! includingEntity && entity == aPartyPlayer )
            continue;
        [players addObject:aPartyPlayer];
    }
    
    return players;
}

@end
