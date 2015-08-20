//
//  InfinitQuotaWindowController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitQuotaWindowController.h"

#import <Gap/InfinitAccountManager.h>
#import <Gap/InfinitColor.h>
#import <Gap/InfinitConstants.h>
#import <Gap/InfinitStateManager.h>

@interface InfinitQuotaMainView : NSView
@end

@interface InfinitQuotaWindowController ()

@property (nonatomic, strong) IBOutlet NSTextField* details_label;
@property (nonatomic, strong) IBOutlet NSButton* invite_button;
@property (nonatomic, strong) IBOutlet NSTextField* title_label;

@end

@implementation InfinitQuotaMainView

- (void)drawRect:(NSRect)dirtyRect
{
  [[NSColor whiteColor] set];
  NSRectFill(self.bounds);
  [[InfinitColor colorWithGray:237] set];
  NSRectFill(NSMakeRect(0.0f, 1.0f, self.bounds.size.width, 1.0f));
}

@end

@implementation InfinitQuotaWindowController

- (void)showWithTitleText:(NSString*)title
                  details:(NSString*)details
      inviteButtonEnabled:(BOOL)invite_enabled
{
  [super showWindow:self];
  self.title_label.stringValue = title;
  self.details_label.stringValue = details;
  self.invite_button.hidden = !invite_enabled;
  self.window.level = kCGFloatingWindowLevel;
  [self.window center];
}

#pragma mark - Button Handling

- (IBAction)cancelClicked:(id)sender
{
  [self.window close];
  [self.delegate gotCancel];
}

- (IBAction)upgradeClicked:(id)sender
{
  [self.window close];
  InfinitStateManager* manager = [InfinitStateManager sharedInstance];
  [manager webLoginTokenWithCompletionBlock:^(InfinitStateResult* result,
                                              NSString* token,
                                              NSString* email)
   {
     if (!result.success || !token.length || !email.length)
       return;
     NSString* url_str =
       [kInfinitUpgradePlanURL stringByAppendingFormat:@"&login_token=%@&email=%@",
        token, email];
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url_str]];
   }];
  [self.delegate gotUpgrade];
}

- (IBAction)inviteClicked:(id)sender
{
  [self.window close];
  InfinitStateManager* manager = [InfinitStateManager sharedInstance];
  [manager webLoginTokenWithCompletionBlock:^(InfinitStateResult* result,
                                              NSString* token,
                                              NSString* email)
   {
     if (!result.success || !token.length || !email.length)
       return;
     NSString* url_str =
       [kInfinitReferalInviteURL stringByAppendingFormat:@"&login_token=%@&email=%@",
        token, email];
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url_str]];
   }];
  [self.delegate gotInvite];
}

@end
