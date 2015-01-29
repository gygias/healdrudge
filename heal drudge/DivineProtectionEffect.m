//
//  DivineProtectionEffect.m
//  heal drudge
//
//  Created by david on 1/28/15.
//  Copyright (c) 2015 Combobulated Software. All rights reserved.
//

#import "DivineProtectionEffect.h"

#import "ImageFactory.h"

@implementation DivineProtectionEffect

- (id)init
{
    if ( self = [super init] )
    {
        self.name = @"Divine Protection";
        self.duration = 8;
        self.image = [ImageFactory imageNamed:@"divine_protection"];
        self.drawsInFrame = YES;
        self.effectType = BeneficialEffect;
    }
    
    return self;
}

- (BOOL)handleSpell:(Spell *)spell asSource:(BOOL)asSource source:(Entity *)source target:(Entity *)target modifier:(NSMutableArray *)modifiers handler:(EffectEventHandler)handler
{
    EventModifier *mod = [EventModifier new];
    mod.damageTakenDecreasePercentage = @0.4; // TODO
    [modifiers addObject:mod];
    return YES;
}

@end