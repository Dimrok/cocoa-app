//
//  InfinitSettingsWindow.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSettingsWindow.h"

#import "InfinitSettingsAccountView.h"
#import "InfinitSettingsGeneralView.h"
#import "InfinitSettingsScreenshotView.h"

#import <Gap/InfinitStateManager.h>

@interface InfinitSettingsWindow () <NSWindowDelegate,
                                     InfinitSettingsAccountProtocol,
                                     InfinitSettingsGeneralProtocol>

@property (nonatomic, weak) IBOutlet NSToolbarItem* account_button;
@property (nonatomic, weak) IBOutlet NSToolbarItem* general_button;
@property (nonatomic, weak) IBOutlet NSToolbarItem* screenshot_button;
@property (nonatomic, weak) IBOutlet NSToolbar* toolbar;

@property (nonatomic, readonly) InfinitSettingsAccountView* account_view;
@property (nonatomic, readonly) InfinitSettingsGeneralView* general_view;
@property (nonatomic, readonly) InfinitSettingsScreenshotView* screenshot_view;

@end

static InfinitSettingsWindow* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitSettingsWindow

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super initWithWindowNibName:self.className])
  {
    _account_view = [[InfinitSettingsAccountView alloc] initWithDelegate:self];
    _general_view = [[InfinitSettingsGeneralView alloc] initWithDelegate:self];
    NSString* name = NSStringFromClass(InfinitSettingsScreenshotView.class);
    _screenshot_view = [[InfinitSettingsScreenshotView alloc] initWithNibName:name bundle:nil];
    self.window.level = NSFloatingWindowLevel;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willLogout)
                                                 name:INFINIT_WILL_LOGOUT_NOTIFICATION 
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  _instance_token = 0;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitSettingsWindow alloc] init];
  });
  return _instance;
}

#pragma mark - Public

- (void)showWindow:(id)sender
{
  self.window.alphaValue = 0.0f;
  [super showWindow:sender];
  [self.account_view loadData];
  self.account_button.enabled = YES;
  self.general_button.enabled = YES;
  self.screenshot_button.enabled = YES;
  self.toolbar.selectedItemIdentifier = @"general_toolbar_item";
  [self changeToViewController:self.general_view withAnimation:NO];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [self.window center];
    self.window.alphaValue = 1.0f;
  });
}

#pragma mark - Change View

- (void)changeToViewController:(InfinitSettingsViewController*)controller
                 withAnimation:(BOOL)animate
{
  CGFloat d_height =
    [controller startSize].height - [self.window.contentView frame].size.height;
  self.window.contentView = controller.view;
  [controller loadData];
  NSRect new_rect = NSMakeRect(self.window.frame.origin.x,
                               self.window.frame.origin.y - d_height,
                               self.window.frame.size.width, self.window.frame.size.height + d_height);
  [self.window setFrame:new_rect display:YES animate:animate];
}

- (IBAction)accountClicked:(NSToolbarItem*)sender
{
  [self changeToViewController:self.account_view withAnimation:YES];
}

- (IBAction)generalClicked:(NSToolbarItem*)sender
{
  [self changeToViewController:self.general_view withAnimation:YES];
}

- (IBAction)screenshotsClicked:(NSToolbarItem*)sender
{
  [self changeToViewController:self.screenshot_view withAnimation:YES];
}

#pragma mark - Account View Protocol

- (NSWindow*)getWindow:(InfinitSettingsAccountView*)sender
{
  return self.window;
}

- (void)closeSettingsWindow:(InfinitSettingsAccountView*)sender
{
  [self close];
}

#pragma mark - General View Protocol

- (BOOL)infinitInLoginItems:(InfinitSettingsGeneralView*)sender
{
  return [self.delegate infinitInLoginItems:self];
}

- (void)setInfinitInLoginItems:(InfinitSettingsGeneralView*)sender
                            to:(BOOL)value
{
  [_delegate setInfinitInLoginItems:self to:value];
}

- (BOOL)stayAwake:(InfinitSettingsGeneralView*)sender
{
  return [self.delegate stayAwake:self];
}

- (void)setStayAwake:(InfinitSettingsGeneralView*)sender
                  to:(BOOL)value
{
  [self.delegate setStayAwake:self to:value];
}

- (void)checkForUpdate:(InfinitSettingsGeneralView*)sender
{
  [self.delegate checkForUpdate:self];
}

#pragma mark - Window Delegate

- (BOOL)windowShouldClose:(id)sender
{
  return YES;
}

#pragma mark - Will Logout

- (void)willLogout
{
  [self close];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(200 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    _instance = nil;
  });
}

@end
