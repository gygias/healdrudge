//
//  Encounter.h
//  heal drudge
//
//  Created by david on 1/22/15.
//  Copyright (c) 2015 Combobulated Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Entity.h"
#import "Enemy.h"
#import "Raid.h"
#import "Ability.h"

typedef void(^EncounterUpdatedBlock)(Encounter *);
typedef void(^EnemyAbilityBlock)(Enemy *, Ability *);

@interface Encounter : NSObject
{
    dispatch_queue_t _encounterQueue;
    dispatch_source_t _encounterTimer;
}

@property Entity *player;
@property Raid *raid;
@property NSArray *enemies;
@property NSDate *startDate;
@property (nonatomic,copy) EncounterUpdatedBlock encounterUpdatedHandler;
@property (nonatomic,copy) EnemyAbilityBlock enemyAbilityHandler;

@property (nonatomic,readonly) dispatch_queue_t encounterQueue;

- (void)start;
- (void)end;

// called by entities when the a timed spell goes off
- (void)handleSpell:(Spell *)spell source:(Entity *)source target:(Entity *)target periodicTick:(BOOL)periodicTick periodicTickSource:(dispatch_source_t)periodicTickSource isFirstTick:(BOOL)firstTick;

- (void)doDamage:(Spell *)spell source:(Entity *)source target:(Entity *)target modifiers:(NSArray *)modifiers periodic:(BOOL)periodic;
- (void)doHealing:(Spell *)spell source:(Entity *)source target:(Entity *)target modifiers:(NSArray *)modifiers periodic:(BOOL)periodic;

- (BOOL)entityIsTargetedByEntity:(Entity *)entity;

@end

