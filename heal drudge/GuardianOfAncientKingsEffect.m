//
//  GuardianOfAncientKingsEffect.m
//  heal drudge
//
//  Created by david on 1/28/15.
//  Copyright (c) 2015 Combobulated Software. All rights reserved.
//

#import "GuardianOfAncientKingsEffect.h"

#import "ImageFactory.h"

@implementation GuardianOfAncientKingsEffect

- (id)init
{
    if ( self = [super init] )
    {
        self.name = @"Guardian of Ancient Kings";
        self.duration = 12;
        self.image = [ImageFactory imageNamed:@"guardian_of_ancient_kings"];
        self.effectType = BeneficialEffect;
        self.drawsInFrame = YES;
    }
    
    return self;
}

- (BOOL)handleSpell:(Spell *)spell asSource:(BOOL)asSource source:(Entity *)source target:(Entity *)target modifier:(NSMutableArray *)modifiers handler:(EffectEventHandler)handler
{
    if ( asSource )
        return NO;
    
    EventModifier *mod = [EventModifier new];
    mod.damageTakenDecreasePercentage = @0.5;
    [modifiers addObject:mod];
    return YES;
}

@end
