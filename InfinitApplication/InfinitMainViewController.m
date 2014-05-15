//
//  InfinitMainViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "InfinitMainViewController.h"

#import <version.hh>

#define IA_FEEDBACK_LINK "http://feedback.infinit.io"
#define IA_PROFILE_LINK "https://infinit.io/account"

//- Transaction Link View --------------------------------------------------------------------------

@implementation InfinitMainTransactionLinkView
{
@private
  id<InfinitMainTransactionLinkProtocol> _delegate;
  NSTrackingArea* _tracking_area;

  NSAttributedString* _link_norm_str;
  NSAttributedString* _link_high_str;
  NSAttributedString* _transaction_norm_str;
  NSAttributedString* _transaction_high_str;
}

- (void)setupView
{
  NSFont* font = [NSFont fontWithName:@"Montserrat" size:11.0];
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSCenterTextAlignment;
  NSDictionary* norm_attrs = [IAFunctions textStyleWithFont:font
                                             paragraphStyle:para
                                                     colour:IA_RGB_COLOUR(81, 82, 73)
                                                     shadow:nil];
  NSDictionary* high_attrs = [IAFunctions textStyleWithFont:font
                                             paragraphStyle:para
                                                     colour:IA_RGB_COLOUR(0, 195, 192)
                                                     shadow:nil];
  NSString* link_str = NSLocalizedString(@"LINKS", nil);
  NSString* transaction_str = NSLocalizedString(@"PEOPLE", nil);

  _link_norm_str = [[NSAttributedString alloc] initWithString:link_str attributes:norm_attrs];
  _link_high_str = [[NSAttributedString alloc] initWithString:link_str attributes:high_attrs];

  _transaction_norm_str = [[NSAttributedString alloc] initWithString:transaction_str
                                                          attributes:norm_attrs];
  _transaction_high_str = [[NSAttributedString alloc] initWithString:transaction_str
                                                          attributes:high_attrs];

  self.transaction_text.attributedStringValue = _transaction_high_str;
  self.link_text.attributedStringValue = _link_norm_str;
  self.transaction_counter.highlighted = YES;
  self.link_counter.highlighted = NO;
}

- (void)setDelegate:(id<InfinitMainTransactionLinkProtocol>)delegate
{
  _delegate = delegate;
}

- (void)setLinkCount:(NSUInteger)count
{
  self.link_counter.count = count;
}

- (void)setTransactionCount:(NSUInteger)count
{
  self.transaction_counter.count = count;
}

- (BOOL)isOpaque
{
  return NO;
}

- (void)dealloc
{
  _tracking_area = nil;
}

- (void)setAnimate_mode:(CGFloat)animate_mode
{
  _animate_mode = animate_mode;
  [self setNeedsDisplay:YES];
}

- (void)setMode:(InfinitTransactionLinkMode)mode
{
  if (_mode == mode)
    return;
  _mode = mode;
  CGFloat val;
  if (_mode == INFINIT_MAIN_VIEW_TRANSACTION_MODE)
  {
    self.transaction_text.attributedStringValue = _transaction_high_str;
    self.link_text.attributedStringValue = _link_norm_str;
    self.link_counter.highlighted = NO;
    self.transaction_counter.highlighted = YES;
    val = 0.0;
  }
  else
  {
    self.transaction_text.attributedStringValue = _transaction_norm_str;
    self.link_text.attributedStringValue = _link_high_str;
    self.link_counter.highlighted = YES;
    self.transaction_counter.highlighted = NO;
    val = 1.0;
  }

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
   {
     context.duration = 0.2;
     context.timingFunction =
       [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
     [self.animator setAnimate_mode:val];
   }
                      completionHandler:^
   {
     _animate_mode = val;
   }];
}

//- Animation --------------------------------------------------------------------------------------

+ (id)defaultAnimationForKey:(NSString*)key
{
  if ([key isEqualToString:@"animate_mode"])
    return [CABasicAnimation animation];

  return [super defaultAnimationForKey:key];
}

//- Mouse Handling ---------------------------------------------------------------------------------

- (void)resetCursorRects
{
  [super resetCursorRects];
  NSCursor* cursor = [NSCursor pointingHandCursor];
  [self addCursorRect:self.bounds cursor:cursor];
}


- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];

  [self addTrackingArea:_tracking_area];

  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
  else
    [self mouseExited:nil];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
}

- (void)mouseExited:(NSEvent*)theEvent
{
}

- (void)mouseDown:(NSEvent*)theEvent
{
  NSPoint click_loc = theEvent.locationInWindow;
  if (click_loc.x < self.bounds.size.width / 2.0)
    [_delegate gotUserClick:self];
  else
    [_delegate gotLinkClick:self];
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* bg = [IAFunctions roundedTopBezierWithRect:self.bounds cornerRadius:6.0];
  [IA_GREY_COLOUR(255) set];
  [bg fill];
  NSBezierPath* light_line =
  [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0, NSWidth(self.bounds), 2.0)];
  [IA_GREY_COLOUR(230) set];
  [light_line fill];
  NSRect dark_rect = {
    .origin = NSMakePoint((NSWidth(self.bounds) / 2.0) * _animate_mode, 0.0),
    .size = NSMakeSize(NSWidth(self.bounds) / 2.0, 2.0)
  };
  NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:dark_rect];
  [IA_RGB_COLOUR(0, 195, 192) set];
  [dark_line fill];
}

@end

//- Main Controller --------------------------------------------------------------------------------

@interface InfinitMainViewController ()
@end

@implementation InfinitMainViewController
{
@private
  id<InfinitMainViewProtocol> _delegate;

  InfinitTransactionViewController* _transaction_controller;
  InfinitLinkViewController* _link_controller;
  NSViewController* _current_controller;

  NSString* _version_str;
}

- (id)initWithDelegate:(id<InfinitMainViewProtocol>)delegate
    andTransactionList:(NSArray*)transaction_list
           andLinkList:(NSArray*)link_list
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _transaction_controller =
      [[InfinitTransactionViewController alloc] initWithDelegate:self
                                              andTransactionList:transaction_list];
    _link_controller =
      [[InfinitLinkViewController alloc] initWithDelegate:self andLinkList:link_list];
    _current_controller = _transaction_controller;
    _version_str =
      [NSString stringWithFormat:@"v%@", [NSString stringWithUTF8String:INFINIT_VERSION]];
  }
  return self;
}

- (void)awakeFromNib
{
  [self.main_view addSubview:_current_controller.view];
  NSArray* contraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                            options:0
                                            metrics:nil
                                              views:@{@"view": _current_controller.view}];
  [self.main_view addConstraints:contraints];

  if ([_delegate autostart:self])
    _auto_start_toggle.state = NSOnState;
  else
    _auto_start_toggle.state = NSOffState;
  _version_item.title = _version_str;
}

- (CATransition*)transitionFromLeft:(BOOL)from_left
{
  CATransition* transition = [CATransition animation];
  transition.type = kCATransitionPush;
  if (from_left)
    transition.subtype = kCATransitionFromLeft;
  else
    transition.subtype = kCATransitionFromRight;
  return transition;
}

- (void)loadView
{
  [super loadView];
  [self.view_selector setDelegate:self];
  [self.view_selector setupView];
  [self.view_selector setLinkCount:_link_controller.linksRunning];
  [self.view_selector setTransactionCount:_transaction_controller.unreadRows];
}

//- IAViewController -------------------------------------------------------------------------------

- (BOOL)closeOnFocusLost
{
  return YES;
}

- (void)aboutToChangeView
{
  if (_current_controller == _transaction_controller)
    _transaction_controller.changing = YES;
  [_transaction_controller markTransactionsRead];
}

- (void)transactionAdded:(IATransaction*)transaction
{
  if (_current_controller != _transaction_controller)
    return;
  [_transaction_controller transactionAdded:transaction];
  [self.view_selector setTransactionCount:_transaction_controller.unreadRows];
}

- (void)transactionUpdated:(IATransaction*)transaction
{
  if (_current_controller != _transaction_controller)
    return;
  [_transaction_controller transactionUpdated:transaction];
  [self.view_selector setTransactionCount:_transaction_controller.unreadRows];
}

- (void)userUpdated:(IAUser*)user
{
  if (_current_controller != _transaction_controller)
    return;
  [_transaction_controller userUpdated:user];
}

//- Link View Protocol -----------------------------------------------------------------------------


//- Peer Transaction Protocol ----------------------------------------------------------------------

- (void)transactionsViewResizeToHeight:(CGFloat)height
{
  if (height == self.content_height_constraint.constant)
    return;

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
  }
                      completionHandler:^
  {
    [self.content_height_constraint.animator setConstant:height];
  }];
}

- (NSUInteger)runningTransactionsForUser:(IAUser*)user
{
  return [_delegate runningTransactionsForUser:user];
}

- (NSUInteger)notDoneTransactionsForUser:(IAUser*)user
{
  return [_delegate notDoneTransactionsForUser:user];
}

- (NSUInteger)unreadTransactionsForUser:(IAUser*)user
{
  return [_delegate unreadTransactionsForUser:user];
}

- (CGFloat)totalProgressForUser:(IAUser*)user
{
  return [_delegate totalProgressForUser:user];
}

- (BOOL)transferringTransactionsForUser:(IAUser*)user
{
  return [_delegate transferringTransactionsForUser:user];
}

- (void)userGotClicked:(IAUser*)user
{
  _transaction_controller.changing = YES;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.content_height_constraint.animator setConstant:0.0];
  }
                      completionHandler:^
  {
    [_delegate userGotClicked:user];
  }];
}

- (void)markTransactionRead:(IATransaction*)transaction
{
  [_delegate markTransactionRead:transaction];
}

//- Transaction Link Protocol ----------------------------------------------------------------------

- (void)gotUserClick:(InfinitMainTransactionLinkView*)sender
{
  if (_current_controller == _transaction_controller)
    return;

  if (self.main_view.wantsLayer == NO)
    self.main_view.wantsLayer = YES;

  [_transaction_controller updateModelWithList:[_delegate latestTransactionsByUser:self]];

  [self.view_selector setMode:INFINIT_MAIN_VIEW_TRANSACTION_MODE];
  _link_controller.changing = YES;
  self.main_view.animations = @{@"subviews": [self transitionFromLeft:NO]};
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     [self.main_view.animator replaceSubview:_current_controller.view
                                        with:_transaction_controller.view];
     _current_controller = _transaction_controller;
   }
                      completionHandler:^
   {
     NSArray* constraints =
       [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                               options:0
                                               metrics:nil
                                                 views:@{@"view": _current_controller.view}];
     [self.main_view addConstraints:constraints];
     if (self.content_height_constraint.constant != _transaction_controller.height)
     {
       [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
        {
          context.duration = 0.15;
          [self.content_height_constraint.animator setConstant:_transaction_controller.height];
        }
                           completionHandler:^
        {
          _transaction_controller.changing = NO;
        }];
     }
     else
     {
       _transaction_controller.changing = NO;
     }
   }];
}

- (void)gotLinkClick:(InfinitMainTransactionLinkView*)sender
{
  if (_current_controller == _link_controller)
    return;

  if (self.main_view.wantsLayer == NO)
    self.main_view.wantsLayer = YES;

  [_transaction_controller markTransactionsRead];
  [self.view_selector setMode:INFINIT_MAIN_VIEW_LINK_MODE];
  _transaction_controller.changing = YES;
  self.main_view.animations = @{@"subviews": [self transitionFromLeft:YES]};
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.main_view.animator replaceSubview:_current_controller.view with:_link_controller.view];
    _current_controller = _link_controller;
  }
                      completionHandler:^
  {
    NSArray* constraints =
      [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                              options:0
                                              metrics:nil
                                                views:@{@"view": _current_controller.view}];
    [self.main_view addConstraints:constraints];
    if (self.content_height_constraint.constant != _link_controller.height)
    {
      [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
      {
        context.duration = 0.15;
        [self.content_height_constraint.animator setConstant:_link_controller.height];
      }
                          completionHandler:^
      {
        _link_controller.changing = NO;
      }];
    }
    else
    {
      _link_controller.changing = NO;
    }
  }];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)gearButtonClicked:(NSButton*)sender
{
  NSPoint point = NSMakePoint(sender.frame.origin.x + NSWidth(sender.frame),
                              sender.frame.origin.y);
  NSPoint menu_origin = [sender.superview convertPoint:point toView:nil];
  NSEvent* event = [NSEvent mouseEventWithType:NSLeftMouseDown
                                      location:menu_origin
                                 modifierFlags:NSLeftMouseDownMask
                                     timestamp:0
                                  windowNumber:sender.window.windowNumber
                                       context:sender.window.graphicsContext
                                   eventNumber:0
                                    clickCount:1
                                      pressure:1];
  [NSMenu popUpContextMenu:_gear_menu withEvent:event forView:sender];
}

- (IBAction)sendButtonClicked:(NSButton*)sender
{
  _transaction_controller.changing = YES;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.content_height_constraint.animator setConstant:0.0];
  } completionHandler:^
  {
    if (self.view_selector.mode == INFINIT_MAIN_VIEW_TRANSACTION_MODE)
      [_delegate sendGotClicked:self];
    else
      [_delegate makeLinkGotClicked:self];
  }];
}

- (IBAction)quitClicked:(NSMenuItem*)sender
{
  [_delegate quit:self];
}

- (IBAction)logoutClicked:(NSMenuItem*)sender
{
  [_delegate logout:self];
}

- (IBAction)onFeedbackClick:(NSMenuItem*)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:
                                          [NSString stringWithUTF8String:IA_FEEDBACK_LINK]]];
}

- (IBAction)onProfileClick:(NSMenuItem*)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:
                                          [NSString stringWithUTF8String:IA_PROFILE_LINK]]];
}

- (IBAction)onReportProblemClick:(NSMenuItem*)sender
{
  [_delegate reportAProblem:self];
}

- (IBAction)onCheckForUpdateClick:(NSMenuItem*)sender
{
  [_delegate checkForUpdate:self];
}

- (IBAction)onToggleAutoStartClick:(NSMenuItem*)sender
{
  if (sender.state == NSOffState)
  {
    sender.state = NSOnState;
    [_delegate setAutoStart:YES];
  }
  else
  {
    sender.state = NSOffState;
    [_delegate setAutoStart:NO];
  }
}

@end
