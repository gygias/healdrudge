//
//  Entity.m
//  heal drudge
//
//  Created by david on 1/22/15.
//  Copyright (c) 2015 Combobulated Software. All rights reserved.
//

#import "Entity.h"

#import "Encounter.h"
#import "Effect.h"
#import "Spell.h"
#import "ItemLevelAndStatsConverter.h"

#import "GenericDamageSpell.h"
#import "GenericHealingSpell.h"

@implementation Entity

@synthesize currentHealth = _currentHealth,
            currentResources = _currentResources,
            statusEffects = _statusEffects,
            periodicEffectQueue = _periodicEffectQueue;

- (id)init
{
    if ( self = [super init] )
    {
        self.emittingSounds = [NSMutableArray new];
    }
    return self;
}

- (dispatch_queue_t)periodicEffectQueue
{
    if ( ! _periodicEffectQueue )
    {
        NSString *queueName = [NSString stringWithFormat:@"%@-PeriodicEffectQueue",self];
        _periodicEffectQueue = dispatch_queue_create([queueName UTF8String], 0);
    }
    
    return _periodicEffectQueue;
}

- (BOOL)validateSpell:(Spell *)spell asSource:(BOOL)asSource otherEntity:(Entity *)otherEntity message:(NSString **)messagePtr invalidDueToCooldown:(BOOL *)invalidDueToCooldown
{
    Entity *source = asSource ? self : otherEntity;
    Entity *target = asSource ? otherEntity : self;
    
    if ( source.currentResources.integerValue < spell.manaCost.integerValue )
    {
        if ( messagePtr )
            *messagePtr = @"Not enough mana";
        return NO;
    }
    else if ( source.isDead )
    {
        if ( messagePtr )
            *messagePtr = @"You are dead";
        return NO;
    }
    else if ( target.isDead && ! spell.canBeCastOnDeadEntities )
    {
        if ( messagePtr )
            *messagePtr = @"Target is dead";
        return NO;
    }
    else if ( spell.spellType == DetrimentalSpell )
    {
        if ( target.isPlayer )
        {
            if ( messagePtr )
                *messagePtr = @"Invalid target";
            return NO;
        }
    }
    else if ( spell.spellType == BeneficialSpell )
    {
        if ( target.isEnemy )
        {
            if ( messagePtr )
                *messagePtr = @"Invalid target";
            return NO;
        }
    }
        
    if ( ! [spell validateWithSource:source target:self message:messagePtr] )
        return NO;
    
    __block BOOL okay = YES;
    [_statusEffects enumerateObjectsUsingBlock:^(Effect *obj, NSUInteger idx, BOOL *stop) {
        
        if ( ! [obj validateSpell:spell asEffectOfSource:asSource source:source target:target message:messagePtr] )
        {
            okay = NO;
            *stop = YES;
        }
    }];
    
    [target.statusEffects enumerateObjectsUsingBlock:^(Effect *obj, NSUInteger idx, BOOL *stop) {
        if ( ! [obj validateSpell:spell asEffectOfSource:!asSource source:source target:target message:messagePtr] )
        {
            okay = NO;
            *stop = YES;
        }
    }];
    
    if ( okay )
    {
        if ( spell.nextCooldownDate || self.nextGlobalCooldownDate )
        {
            if ( messagePtr )
                *messagePtr = @"Not ready yet";
            if ( invalidDueToCooldown )
                *invalidDueToCooldown = YES;
            return NO;
        }
    }
    
    return okay;
}

- (BOOL)handleSpellStart:(Spell *)spell asSource:(BOOL)asSource otherEntity:(Entity *)otherEntity modifiers:(NSMutableArray *)modifiers
{
    __block BOOL addedModifiers = NO;
    
    Entity *source = asSource ? self : otherEntity;
    Entity *target = asSource ? otherEntity : self;
    if ( [spell handleStartWithSource:source target:target modifiers:modifiers] )
        addedModifiers = YES;
    
    [self.statusEffects enumerateObjectsUsingBlock:^(Effect *obj, NSUInteger idx, BOOL *stop) {
        if ( [obj handleSpellStarted:spell asSource:asSource source:source target:target modifier:modifiers handler:^(BOOL consumesEffect) {
            // this is fucking hideous
            if ( consumesEffect )
            {
                dispatch_async(dispatch_get_current_queue(), ^{
                    [self removeStatusEffect:obj];
                });
            }
        }] )
            addedModifiers = YES;
    }];
    
    return addedModifiers;
}

- (BOOL)handleSpell:(Spell *)spell asSource:(BOOL)asSource otherEntity:(Entity *)otherEntity modifiers:(NSMutableArray *)modifiers
{
    __block BOOL addedModifiers = NO;
    
    Entity *source = asSource ? self : otherEntity;
    Entity *target = asSource ? otherEntity : self;
    
    [self.statusEffects enumerateObjectsUsingBlock:^(Effect *obj, NSUInteger idx, BOOL *stop) {
        if ( [obj handleSpell:spell asSource:asSource source:source target:target modifier:modifiers handler:^(BOOL consumesEffect) {
            // this is fucking hideous
            if ( consumesEffect )
            {
                dispatch_async(dispatch_get_current_queue(), ^{
                    [self removeStatusEffect:obj];
                });
            }
        }] )
            addedModifiers = YES;
    }];
    
    return addedModifiers;
}

- (BOOL)handleSpellEnd:(Spell *)spell asSource:(BOOL)asSource otherEntity:(Entity *)otherEntity modifiers:(NSMutableArray *)modifiers
{
    return NO;
}

- (void)addStatusEffect:(Effect *)statusEffect source:(Entity *)source
{
    if ( ! _statusEffects )
        _statusEffects = [NSMutableArray new];
    statusEffect.startDate = [NSDate date];
    statusEffect.source = source;
    [(NSMutableArray *)_statusEffects addObject:statusEffect];
    NSLog(@"%@ is affected by %@",self,statusEffect);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(statusEffect.duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ( [_statusEffects containsObject:statusEffect] )
        {
            NSLog(@"%@ on %@ has timed out",statusEffect,self);
            [(NSMutableArray *)_statusEffects removeObject:statusEffect];
        }
        else
            NSLog(@"%@ on %@ was removed some other way",statusEffect,self);
    });
}

- (void)removeStatusEffect:(Effect *)effect
{
    [(NSMutableArray *)_statusEffects removeObject:effect];
    NSLog(@"removed %@'s %@",self,effect);
}

- (void)removeStatusEffectNamed:(NSString *)statusEffectName
{
    __block id object = nil;
    [_statusEffects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ( [NSStringFromClass([obj class]) isEqualToString:statusEffectName] )
        {
            object = obj;
            *stop = YES;
        }
    }];
    
    if ( object )
        [self removeStatusEffect:object];
}

- (void)handleDeathOfEntity:(Entity *)dyingEntity fromAbility:(Ability *)ability
{
    if ( dyingEntity == self )
    {
        NSLog(@"%@ has died",self);
        self.isDead = YES;
        
        Effect *aStatusEffect = nil;
        while ( ( aStatusEffect = [self.statusEffects lastObject] ) )
            [self removeStatusEffect:aStatusEffect];
    }
}

- (void)prepareForEncounter:(Encounter *)encounter
{
    self.currentHealth = self.health;
    self.currentResources = self.power;
}

- (void)beginEncounter:(Encounter *)encounter
{
    NSLog(@"i, %@ (%@), should begin encounter",self,self.isPlayingPlayer?@"playing player":@"automated player");
    
    if ( ! self.isPlayingPlayer )
    {
        self.automaticAbilitySource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, encounter.encounterQueue);
        NSNumber *gcd = [ItemLevelAndStatsConverter globalCooldownWithEntity:self hasteBuffPercentage:nil];
        NSNumber *gcdWithStagger = @( ( arc4random() % (int)gcd.doubleValue * 100000 ) / 100000 + gcd.doubleValue );
        dispatch_source_set_timer(self.automaticAbilitySource, DISPATCH_TIME_NOW, gcdWithStagger.doubleValue * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.automaticAbilitySource, ^{
            
            [self _doAutomaticStuffWithEncounter:encounter];
            
        });
        dispatch_resume(self.automaticAbilitySource);
    }
}

- (void)_doAutomaticStuffWithEncounter:(Encounter *)encounter
{
    //if ( ! self.lastAutomaticAbilityDate ||
    //    [[NSDate date] timeIntervalSinceDate:self.lastAutomaticAbilityDate] )
    //NSLog(@"%@ is doing automated stuff",self);
    {
        if ( [self.hdClass.role isEqualToString:(NSString *)TankRole] )
        {
            [self _doAutomaticTankingWithEncounter:encounter];
        }
        else if ( [self.hdClass.role isEqualToString:(NSString *)DPSRole] )
        {
            [self _doAutomaticDPSWithEncounter:encounter];
        }
        else if ( [self.hdClass.role isEqualToString:(NSString *)HealerRole] )
        {
            [self _doAutomaticHealingWithEncounter:encounter];
        }
        
        self.lastAutomaticAbilityDate = [NSDate date];
    }
}

- (void)_doAutomaticTankingWithEncounter:(Encounter *)encounter
{
    
}

- (void)_doAutomaticDPSWithEncounter:(Encounter *)encounter
{
    NSInteger randomEnemy = arc4random() % encounter.enemies.count;
    Entity *enemy = encounter.enemies[randomEnemy];
    Spell *spell = [[GenericDamageSpell alloc] initWithCaster:self];
    [encounter doDamage:spell source:self target:enemy modifiers:nil periodic:NO];
}

- (void)_doAutomaticHealingWithEncounter:(Encounter *)encounter
{
    [encounter.raid.players enumerateObjectsUsingBlock:^(Entity *player, NSUInteger idx, BOOL *stop) {
        if ( player.currentHealth.doubleValue < player.health.doubleValue )
        {
            //NSNumber *averageHealing = [ItemLevelAndStatsConverter automaticHealValueWithEntity:self];
            Spell *spell = [[GenericHealingSpell alloc] initWithCaster:self];
            NSLog(@"%@ is healing %@ for %@",self,player,spell.healing);
            [encounter doHealing:spell source:self target:player modifiers:nil periodic:NO];
            //player.currentHealth = ( player.currentHealth.doubleValue + averageHealing.doubleValue > player.health.doubleValue ) ?
            //                        ( player.health ) : @( player.currentHealth.doubleValue + averageHealing.doubleValue );
        }
    }];
}

- (void)updateEncounter:(Encounter *)encounter
{
    //NSLog(@"i, %@, should update encounter",self);
    
    // TODO enumerate and remove status effects
}

- (void)endEncounter:(Encounter *)encounter
{
    //NSLog(@"i, %@, should end encounter",self);
    self.stopped = YES;
}

// character


@synthesize image; // no fucking idea XXX

+ (NSArray *)primaryStatKeys
{
    return @[ @"intellect", @"strength", @"agility" ];
}

+ (NSArray *)secondaryStatKeys
{
    return @[ @"critRating", @"hasteRating", @"masteryRating" ];
}

+ (NSArray *)tertiaryStatKeys
{
    return @[ @"versatilityRating", @"multistrikeRating", @"leechRating" ];
}

- (NSNumber *)health
{
    return [ItemLevelAndStatsConverter healthFromStamina:self.stamina];
}

- (NSNumber *)baseMana
{
    return self.power;
}

- (NSNumber *)spellPower
{
    return [ItemLevelAndStatsConverter spellPowerFromIntellect:self.intellect];
}

- (NSNumber *)attackPower
{
    return [ItemLevelAndStatsConverter attackPowerBonusFromAgility:self.agility andStrength:self.strength];
}

- (NSNumber *)primaryStat
{
    return [self valueForKey:self.hdClass.primaryStatKey];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@)",self.name,self.hdClass];
    //return [NSString stringWithFormat:@"%@ (%@)\n\t%@ health %@ power %@ int %@ agil %@ str %@ crit %@ haste %@ mastery",self.name,self.hdClass,self.health,self.power,self.intellect,self.agility,self.strength,self.critRating,self.hasteRating,self.masteryRating];
}

@end
