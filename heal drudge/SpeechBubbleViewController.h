//
//  TankExplanationView.h
//  heal drudge
//
//  Created by david on 2/7/15.
//  Copyright (c) 2015 Combobulated Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SpeechBubbleView.h"
#import "SpeechBubbleContentView.h"

@interface SpeechBubbleViewController : UIViewController

+ (SpeechBubbleViewController *)speechBubbleViewControllerWithImage:(UIImage *)image text:(NSString *)text;
+ (SpeechBubbleViewController *)speechBubbleViewControllerWithCommands;

@property IBOutlet SpeechBubbleView *speechBubbleView;
@property IBOutlet SpeechBubbleContentView *speechBubbleContentView;
@property IBOutlet UIImageView *imageView;
@property IBOutlet UILabel *textLabel;
@property CGPoint bubbleOrigin;
@property (nonatomic,retain) UIView *referenceView;
typedef void (^SpeechBubbleViewControllerDismissedHandler)(SpeechBubbleViewController *);
@property (copy) SpeechBubbleViewControllerDismissedHandler dismissHandler;

- (IBAction)heroPressed:(id)sender;
- (IBAction)stackPressed:(id)sender;
- (IBAction)spreadPressed:(id)sender;

@end
