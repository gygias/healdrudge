//
//  DivineAegisEffect.m
//  heal drudge
//
//  Created by david on 1/24/15.
//  Copyright (c) 2015 Combobulated Software. All rights reserved.
//

#import "DivineAegisEffect.h"

#import "ImageFactory.h"

@implementation DivineAegisEffect

- (id)init
{
    if ( self = [super init] )
    {
        self.name = @"Divine Aegis";
        self.duration = 15;
        self.image = [ImageFactory imageNamed:@"divine_aegis"];
        self.effectType = BeneficialEffect;
    }
    
    return self;
}

@end
