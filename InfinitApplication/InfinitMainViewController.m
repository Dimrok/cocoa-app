//
//  InfinitMainViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "InfinitMainViewController.h"
#import "InfinitMetricsManager.h"
#import "InfinitOnboardingController.h"
#import "InfinitTooltipViewController.h"

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
  NSAttributedString* _link_hover_str;
  NSAttributedString* _link_high_str;

  NSAttributedString* _transaction_norm_str;
  NSAttributedString* _transaction_hover_str;
  NSAttributedString* _transaction_high_str;

  BOOL _hover;
}

- (void)setupViewForPeopleView:(BOOL)flag
{
  NSFont* font = [NSFont fontWithName:@"Montserrat" size:11.0];
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSCenterTextAlignment;
  NSDictionary* norm_attrs = [IAFunctions textStyleWithFont:font
                                             paragraphStyle:para
                                                     colour:IA_RGB_COLOUR(139, 139, 131)
                                                     shadow:nil];
  NSDictionary* high_attrs = [IAFunctions textStyleWithFont:font
                                             paragraphStyle:para
                                                     colour:IA_RGB_COLOUR(0, 195, 192)
                                                     shadow:nil];
  NSDictionary* hover_attrs = [IAFunctions textStyleWithFont:font
                                              paragraphStyle:para
                                                      colour:IA_RGB_COLOUR(81, 81, 73)
                                                      shadow:nil];
  NSString* link_str = NSLocalizedString(@"LINKS", nil);
  NSString* transaction_str = NSLocalizedString(@"PEOPLE", nil);

  _link_norm_str = [[NSAttributedString alloc] initWithString:link_str attributes:norm_attrs];
  _link_hover_str = [[NSAttributedString alloc] initWithString:link_str attributes:hover_attrs];
  _link_high_str = [[NSAttributedString alloc] initWithString:link_str attributes:high_attrs];

  _transaction_norm_str = [[NSAttributedString alloc] initWithString:transaction_str
                                                          attributes:norm_attrs];
  _transaction_hover_str = [[NSAttributedString alloc] initWithString:transaction_str
                                                           attributes:hover_attrs];
  _transaction_high_str = [[NSAttributedString alloc] initWithString:transaction_str
                                                          attributes:high_attrs];
  if (flag)
  {
    self.transaction_text.attributedStringValue = _transaction_high_str;
    self.link_text.attributedStringValue = _link_norm_str;
    self.transaction_counter.highlighted = YES;
    self.link_counter.highlighted = NO;
    _mode = INFINIT_MAIN_VIEW_TRANSACTION_MODE;
    _animate_mode = 0.0;
  }
  else
  {
    self.transaction_text.attributedStringValue = _transaction_norm_str;
    self.link_text.attributedStringValue = _link_high_str;
    self.transaction_counter.highlighted = NO;
    self.link_counter.highlighted = YES;
    _mode = INFINIT_MAIN_VIEW_LINK_MODE;
    _animate_mode = 1.0;
  }
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
                                                         NSTrackingMouseMoved |
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

- (void)mouseExited:(NSEvent*)theEvent
{
  _hover = NO;
  if (_mode == INFINIT_MAIN_VIEW_TRANSACTION_MODE)
  {
    self.transaction_text.attributedStringValue = _transaction_high_str;
    self.link_text.attributedStringValue = _link_norm_str;
  }
  else
  {
    self.transaction_text.attributedStringValue = _transaction_norm_str;
    self.link_text.attributedStringValue = _link_high_str;
  }
  [self setNeedsDisplay:YES];
}

- (void)mouseMoved:(NSEvent*)theEvent
{
  NSPoint loc = theEvent.locationInWindow;
  if (loc.x < self.bounds.size.width / 2.0)
  {
    if (_mode == INFINIT_MAIN_VIEW_LINK_MODE)
    {
      self.transaction_text.attributedStringValue = _transaction_hover_str;
      self.link_text.attributedStringValue = _link_high_str;
      _hover = YES;
    }
    else
    {
      self.link_text.attributedStringValue = _link_norm_str;
      _hover = NO;
    }
  }
  else
  {
    if (_mode == INFINIT_MAIN_VIEW_TRANSACTION_MODE)
    {
      self.link_text.attributedStringValue = _link_hover_str;
      self.transaction_text.attributedStringValue = _transaction_high_str;
      _hover = YES;
    }
    else
    {
      self.transaction_text.attributedStringValue = _transaction_norm_str;
      _hover = NO;
    }
  }
  [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent*)theEvent
{
  _hover = NO;
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
  if (_hover)
    [IA_RGB_COLOUR(213, 213, 213) set];
  else
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

  BOOL _auto_start;
  BOOL _auto_upload;
  NSString* _version_str;

  InfinitTooltipViewController* _tooltip;

  BOOL _for_people_view;
}

- (id)initWithDelegate:(id<InfinitMainViewProtocol>)delegate
    andTransactionList:(NSArray*)transaction_list
           andLinkList:(NSArray*)link_list
         forPeopleView:(BOOL)flag
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _for_people_view = flag;
    _delegate = delegate;
    _transaction_controller =
      [[InfinitTransactionViewController alloc] initWithDelegate:self
                                              andTransactionList:transaction_list];
    _link_controller =
      [[InfinitLinkViewController alloc] initWithDelegate:self andLinkList:link_list
                                            andSelfStatus:[_delegate currentSelfStatus:self]];
    if (_for_people_view)
      _current_controller = _transaction_controller;
    else
      _current_controller = _link_controller;

    _version_str =
      [NSString stringWithFormat:@"v%@", [NSString stringWithUTF8String:INFINIT_VERSION]];
    _auto_start = [_delegate autostart:self];
    _auto_upload = [_delegate autoUploadScreenshots:self];
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
  _version_item.title = _version_str;
  if (_auto_start)
    _auto_start_toggle.state = NSOnState;
  else
    _auto_start_toggle.state = NSOffState;

  if (_auto_upload)
    _auto_upload_toggle.state = NSOnState;
  else
    _auto_upload_toggle.state = NSOffState;
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
  [self.view_selector setupViewForPeopleView:_for_people_view];
  [self.view_selector setLinkCount:_link_controller.linksRunning];
  [self.view_selector setTransactionCount:_transaction_controller.unreadRows];

  if (_for_people_view)
  {
    self.send_button.image = [IAFunctions imageNamed:@"icon-transfer"];
    self.send_button.toolTip = NSLocalizedString(@"Send a file", nil);
  }
  else
  {
    self.send_button.image = [IAFunctions imageNamed:@"icon-upload"];
    self.send_button.toolTip = NSLocalizedString(@"Get a link", nil);
  }

  InfinitOnboardingState onboarding_state = [_delegate onboardingState:self];

  if (onboarding_state == INFINIT_ONBOARDING_RECEIVE_NOTIFICATION)
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON];
    [_transaction_controller performSelector:@selector(delayedStartReceiveOnboarding) withObject:nil afterDelay:0.5];
  }
  else if (onboarding_state == INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON ||
           onboarding_state == INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW)
  {
    [_transaction_controller performSelector:@selector(delayedStartReceiveOnboarding) withObject:nil afterDelay:0.5];
  }
  else if (onboarding_state == INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION)
  {
    [self performSelector:@selector(delayedStartSendOnboarding) withObject:nil afterDelay:0.5];
  }
  else if (onboarding_state == INFINIT_ONBOARDING_SEND_FILE_SENDING ||
           onboarding_state == INFINIT_ONBOARDING_SEND_FILE_SENT)
  {
    [_transaction_controller performSelector:@selector(delayedFileSentOnboarding) withObject:nil afterDelay:0.5];
  }
}

- (void)viewChanged
{
  // WORKAROUND stop flashing when changing subview by enabling layer backing. Need to do this once
  // the view has opened so that we get a shadow during opening animation.
  self.main_view.wantsLayer = YES;
  self.main_view.layer.masksToBounds = YES;
}

//- Onboarding -------------------------------------------------------------------------------------

- (void)delayedStartSendOnboarding
{
  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  NSString* message = NSLocalizedString(@"Click here to send a file", nil);
  [_tooltip showPopoverForView:self.send_button
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message
              withPopAnimation:YES
                       forTime:5.0];
}

//- IAViewController -------------------------------------------------------------------------------

- (BOOL)closeOnFocusLost
{
  [_transaction_controller closeToolTips];
  return YES;
}

- (void)aboutToChangeView
{
  if (_current_controller == _transaction_controller)
    _transaction_controller.changing = YES;
  else if (_current_controller == _link_controller)
    _link_controller.changing = YES;
  [_tooltip close];
  [_transaction_controller closeToolTips];
  [_transaction_controller markTransactionsRead];
}

- (void)linkAdded:(InfinitLinkTransaction*)link
{
  if (_current_controller != _link_controller)
    return;
  [_link_controller linkAdded:link];
}

- (void)linkUpdated:(InfinitLinkTransaction*)link
{
  if (_current_controller != _link_controller)
    return;
  [_link_controller linkUpdated:link];
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

- (void)selfStatusChanged:(gap_UserStatus)status
{
  if (_current_controller == _link_controller)
    [_link_controller selfStatusChanged:status];
}

//- Link View Protocol -----------------------------------------------------------------------------

- (void)copyLinkToPasteBoard:(InfinitLinkTransaction*)link
{
  [_delegate copyLinkToClipboard:link];
}

- (void)linksViewResizeToHeight:(CGFloat)height
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
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON &&
      [[_delegate receiveOnboardingTransaction:self] other_user] == user)
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW];
  }
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

- (IATransaction*)receiveOnboardingTransaction:(InfinitTransactionViewController*)sender
{
  return [_delegate receiveOnboardingTransaction:self];
}

- (IATransaction*)sendOnboardingTransaction:(InfinitTransactionViewController*)sender
{
  return [_delegate sendOnboardingTransaction:self];
}

//- Transaction Link Protocol ----------------------------------------------------------------------

- (void)gotUserClick:(InfinitMainTransactionLinkView*)sender
{
  if (_current_controller == _transaction_controller)
    return;

  self.send_button.image = [IAFunctions imageNamed:@"icon-transfer"];
  self.send_button.toolTip = NSLocalizedString(@"Send a file", nil);

  [_transaction_controller updateModelWithList:[_delegate latestTransactionsByUser:self]];
  [_transaction_controller.table_view scrollRowToVisible:0];

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
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_PEOPLE];
}

- (void)gotLinkClick:(InfinitMainTransactionLinkView*)sender
{
  if (_current_controller == _link_controller)
    return;

  [_tooltip close];
  [_transaction_controller closeToolTips];
  [_transaction_controller markTransactionsRead];

  self.send_button.image = [IAFunctions imageNamed:@"icon-upload"];
  self.send_button.toolTip = NSLocalizedString(@"Get a link", nil);

  [_link_controller updateModelWithList:[_delegate linkHistory:self]];
  [_link_controller.table_view scrollRowToVisible:0];

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
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_LINKS];
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
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_DONE)
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION];
  }
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
  if (sender != self.auto_start_toggle)
    return;
  if (self.auto_start_toggle.state == NSOffState)
  {
    self.auto_start_toggle.state = NSOnState;
    [_delegate setAutoStart:YES];
  }
  else
  {
    self.auto_start_toggle.state = NSOffState;
    [_delegate setAutoStart:NO];
  }
}

- (IBAction)onToggleUploadScreenshot:(NSMenuItem*)sender
{
  if (sender != self.auto_upload_toggle)
    return;
  if (self.auto_upload_toggle.state == NSOffState)
  {
    self.auto_upload_toggle.state = NSOnState;
    [_delegate setAutoUploadScreenshots:YES];
  }
  else
  {
    self.auto_upload_toggle.state = NSOffState;
    [_delegate setAutoUploadScreenshots:NO];
  }
}

@end
