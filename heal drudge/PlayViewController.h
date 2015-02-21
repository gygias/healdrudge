//
//  PlayViewController.h
//  heal drudge
//
//  Created by david on 2/20/15.
//  Copyright (c) 2015 Combobulated Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "State.h"
#import "EnemyFrameView.h"
#import "RaidFramesView.h"
#import "SpellBarView.h"
#import "CastBarView.h"
#import "PlayerAndTargetView.h"
#import "AlertTextView.h"
#import "EventTimerView.h"
#import "SpeechBubbleViewController.h"


@interface PlayViewController : UIViewController

+ (PlayViewController *)playViewController;

@property State *state;

typedef void (^PlayViewControllerDismissBlock)(PlayViewController *);
@property (nonatomic,copy) PlayViewControllerDismissBlock dismissHandler;

- (IBAction)menuTouched:(id)sender;

@property IBOutlet EnemyFrameView *enemyFrameView;
@property IBOutlet EventTimerView *eventTimerView;
@property IBOutlet AlertTextView *alertTextView;
@property IBOutlet RaidFramesView *raidFramesView;
@property IBOutlet CastBarView *castBarView;
@property IBOutlet PlayerAndTargetView *playerAndTargetView;
@property IBOutlet SpellBarView *spellBarView;
@property SpeechBubbleViewController *currentSpeechBubble;
@property IBOutlet UIView *advisorGuideView;

// debug
@property IBOutlet UIView *upLeftView;
@property IBOutlet UIView *bottomRightView;

@end