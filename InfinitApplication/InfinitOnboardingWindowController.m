//
//  InfinitOnboardingWindowController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 27/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitOnboardingWindowController.h"

#import "IIOnboardingButtonCell.h"
#import "IIOnboardingViewController1.h"
#import "IIOnboardingViewController2.h"
#import "IIOnboardingViewController3.h"
#import "IIOnboardingViewController4.h"
#import "IIOnboardingViewController5.h"

#import <Gap/InfinitColor.h>

@interface InfinitOnboardingWindowController ()

@property (nonatomic, weak) IBOutlet NSButton* back_button;
@property (nonatomic, weak) IBOutlet NSButton* next_button;
@property (nonatomic, weak) IBOutlet NSView* onboarding_view;
@property (nonatomic, weak) IBOutlet IIOnboardingProgressView* progress_view;

@property (atomic, readwrite) BOOL reached_final;

@property (nonatomic, readonly) IIOnboardingAbstractViewController* current_onboarding;
@property (nonatomic, readonly) IIOnboardingViewController1* onboarding_1;
@property (nonatomic, readonly) IIOnboardingViewController2* onboarding_2;
@property (nonatomic, readonly) IIOnboardingViewController3* onboarding_3;
@property (nonatomic, readonly) IIOnboardingViewController4* onboarding_4;
@property (nonatomic, readonly) IIOnboardingViewController5* onboarding_5;

@end

@implementation InfinitOnboardingWindowController

@synthesize onboarding_1 = _onboarding_1;
@synthesize onboarding_2 = _onboarding_2;
@synthesize onboarding_3 = _onboarding_3;
@synthesize onboarding_4 = _onboarding_4;
@synthesize onboarding_5 = _onboarding_5;

#pragma mark - NSWindow

- (void)showWindow:(id)sender
{
  self.window.alphaValue = 0.0f;
  [super showWindow:sender];
  self.window.level = NSStatusWindowLevel;
  NSColor* text_color = [NSColor whiteColor];
  NSMutableAttributedString* back_str = [self.back_button.attributedTitle mutableCopy];
  [back_str addAttribute:NSForegroundColorAttributeName
                   value:text_color
                   range:NSMakeRange(0, back_str.string.length)];
  self.back_button.attributedTitle = back_str;
  ((IIOnboardingButtonCell*)self.back_button.cell).background_color =
    [InfinitColor colorWithGray:216];
  NSMutableAttributedString* next_str = [self.next_button.attributedTitle mutableCopy];
  [next_str addAttribute:NSForegroundColorAttributeName
                   value:text_color
                   range:NSMakeRange(0, next_str.length)];
  self.next_button.attributedTitle = next_str;
  ((IIOnboardingButtonCell*)self.next_button.cell).background_color =
    [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  self.window.title = NSLocalizedString(@"Infinit", nil);
  [self.window standardWindowButton:NSWindowMiniaturizeButton].hidden = YES;
  [self.window standardWindowButton:NSWindowZoomButton].hidden = YES;
  [self showOnboardingController:self.onboarding_1 animated:NO reverse:NO];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    self.window.alphaValue = 1.0f;
  });
}

- (void)close
{
  [self.current_onboarding aboutToAnimate];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(200 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [self.delegate onboardingWindowDidClose:self];
  });
  [super close];
}


- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  _delegate = nil;
}

#pragma mark - Onboarding Animations

- (void)showOnboardingController:(IIOnboardingAbstractViewController*)controller
                        animated:(BOOL)animate
                         reverse:(BOOL)reverse
{
  if (controller == self.current_onboarding)
    return;
  IIOnboardingAbstractViewController* old_onboarding = self.current_onboarding;
  _current_onboarding = controller;
  self.progress_view.progress_count = controller.screen_number;
  self.back_button.hidden = (controller.screen_number == 1);
  self.next_button.hidden = (controller.screen_number == 6);
  self.progress_view.hidden = (controller.screen_number == 6);
  if (controller.final_screen)
    self.reached_final = YES;
  if (old_onboarding)
    [old_onboarding aboutToAnimate];
  if (!animate)
  {
    [self.onboarding_view addSubview:controller.view];
    if (old_onboarding)
      [old_onboarding.view removeFromSuperview];
    [controller finishedAnimate];
    return;
  }
  [self.onboarding_view addSubview:controller.view
                        positioned:NSWindowAbove
                        relativeTo:old_onboarding.view];
  controller.view.alphaValue = 0.0f;
  CGFloat dx = self.onboarding_view.bounds.size.width;
  if (reverse)
    dx = -dx;
  controller.view.frame = NSMakeRect(dx,
                                     0.0f,
                                     controller.view.bounds.size.width,
                                     controller.view.bounds.size.height);
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.5f;
     if (old_onboarding)
     {
       old_onboarding.view.animator.alphaValue = 0.0f;
       old_onboarding.view.animator.frame = NSMakeRect(-dx,
                                                       0.0f,
                                                       controller.view.bounds.size.width,
                                                       controller.view.bounds.size.height);
     }
     controller.view.animator.alphaValue = 1.0f;
     controller.view.animator.frame = self.onboarding_view.bounds;
   } completionHandler:^
   {
     if (old_onboarding)
       [old_onboarding.view removeFromSuperview];
     [controller finishedAnimate];
   }];
}

#pragma mark - Button Handling

- (IBAction)backClicked:(id)sender
{
  IIOnboardingAbstractViewController* last_controller = nil;
  switch (self.current_onboarding.screen_number)
  {
    case 2:
      last_controller = self.onboarding_1;
      break;
    case 3:
      last_controller = self.onboarding_2;
      break;
    case 4:
      last_controller = self.onboarding_3;
      break;
    case 5:
      last_controller = self.onboarding_4;
      break;

    default:
      return;
  }
  if (last_controller)
    [self showOnboardingController:last_controller animated:YES reverse:YES];
}

- (IBAction)nextClicked:(id)sender
{
  IIOnboardingAbstractViewController* next_controller = nil;
  switch (self.current_onboarding.screen_number)
  {
    case 1:
      next_controller = self.onboarding_2;
      break;
    case 2:
      next_controller = self.onboarding_3;
      break;
    case 3:
      next_controller = self.onboarding_4;
      break;
    case 4:
      next_controller = self.onboarding_5;
      break;
    case 5:
      [self close];
      return;

    default:
      return;
  }
  if (next_controller)
    [self showOnboardingController:next_controller animated:YES reverse:NO];
}


#pragma mark - Lazy Loaders

- (IIOnboardingViewController1*)onboarding_1
{
  if (!_onboarding_1)
  {
    NSString* name = NSStringFromClass(IIOnboardingViewController1.class);
    _onboarding_1 = [[IIOnboardingViewController1 alloc] initWithNibName:name bundle:nil];
  }
  return _onboarding_1;
}

- (IIOnboardingViewController2*)onboarding_2
{
  if (!_onboarding_2)
  {
    NSString* name = NSStringFromClass(IIOnboardingVideoAbstractViewController.class);
    _onboarding_2 = [[IIOnboardingViewController2 alloc] initWithNibName:name bundle:nil];
  }
  return _onboarding_2;
}

- (IIOnboardingViewController3*)onboarding_3
{
  if (!_onboarding_3)
  {
    NSString* name = NSStringFromClass(IIOnboardingVideoAbstractViewController.class);
    _onboarding_3 = [[IIOnboardingViewController3 alloc] initWithNibName:name bundle:nil];
  }
  return _onboarding_3;
}

- (IIOnboardingViewController4*)onboarding_4
{
  if (!_onboarding_4)
  {
    NSString* name = NSStringFromClass(IIOnboardingVideoAbstractViewController.class);
    _onboarding_4 = [[IIOnboardingViewController4 alloc] initWithNibName:name bundle:nil];
  }
  return _onboarding_4;
}

- (IIOnboardingViewController5*)onboarding_5
{
  if (!_onboarding_5)
  {
    NSString* name = NSStringFromClass(IIOnboardingViewController5.class);
    _onboarding_5 = [[IIOnboardingViewController5 alloc] initWithNibName:name bundle:nil];
  }
  return _onboarding_5;
}

@end
