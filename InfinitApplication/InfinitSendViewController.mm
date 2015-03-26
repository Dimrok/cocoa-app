//
//  InfinitSendViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendViewController.h"

#import "InfinitMetricsManager.h"
#import "InfinitTooltipViewController.h"

#import <Gap/NSString+email.h>

#import <QuartzCore/QuartzCore.h>

//- User Link View ---------------------------------------------------------------------------------

@implementation InfinitSendUserLinkView
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitSendUserLinkProtocol> _delegate;
  NSTrackingArea* _tracking_area;

  NSAttributedString* _user_hover_str;
  NSAttributedString* _user_high_str;
  NSAttributedString* _user_norm_str;

  NSAttributedString* _link_hover_str;
  NSAttributedString* _link_high_str;
  NSAttributedString* _link_norm_str;

  BOOL _hover;
}

- (void)setupViewForMode:(InfinitUserLinkMode)mode
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
  NSString* link_str = NSLocalizedString(@"GET A LINK", nil);
  NSString* user_str = NSLocalizedString(@"SEND TO SOMEONE", nil);

  _link_high_str = [[NSAttributedString alloc] initWithString:link_str attributes:high_attrs];
  _link_hover_str = [[NSAttributedString alloc] initWithString:link_str attributes:hover_attrs];
  _link_norm_str = [[NSAttributedString alloc] initWithString:link_str attributes:norm_attrs];

  _user_high_str = [[NSAttributedString alloc] initWithString:user_str attributes:high_attrs];
  _user_hover_str = [[NSAttributedString alloc] initWithString:user_str attributes:hover_attrs];
  _user_norm_str = [[NSAttributedString alloc] initWithString:user_str attributes:norm_attrs];

  _mode = mode;
  if (_mode == INFINIT_USER_MODE)
    _animate_mode = 0.0;
  else
    _animate_mode = 1.0;
  if (mode == INFINIT_USER_MODE)
  {
    self.user_text.attributedStringValue = _user_high_str;
    self.link_text.attributedStringValue = _link_norm_str;
  }
  else
  {
    self.user_text.attributedStringValue = _user_norm_str;
    self.link_text.attributedStringValue = _link_high_str;
  }
}

- (void)setDelegate:(id<InfinitSendUserLinkProtocol>)delegate
{
  _delegate = delegate;
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

- (void)setMode:(InfinitUserLinkMode)mode
{
  [self setMode:mode withAnimation:YES];
}

- (void)setMode:(InfinitUserLinkMode)mode
  withAnimation:(BOOL)animate
{
  if (_mode == mode)
    return;
  _mode = mode;
  CGFloat val;
  if (_mode == INFINIT_USER_MODE)
  {
    self.user_text.attributedStringValue = _user_high_str;
    self.link_text.attributedStringValue = _link_norm_str;
    val = 0.0;
  }
  else
  {
    self.user_text.attributedStringValue = _user_norm_str;
    self.link_text.attributedStringValue = _link_high_str;
    val = 1.0;
  }

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
  {
    context.duration = 0.2;
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
  if (_mode == INFINIT_USER_MODE)
  {
    self.user_text.attributedStringValue = _user_high_str;
    self.link_text.attributedStringValue = _link_norm_str;
  }
  else
  {
    self.user_text.attributedStringValue = _user_norm_str;
    self.link_text.attributedStringValue = _link_high_str;
  }
  [self setNeedsDisplay:YES];
}

- (void)mouseMoved:(NSEvent*)theEvent
{
  NSPoint loc = theEvent.locationInWindow;
  if (loc.x < self.bounds.size.width / 2.0)
  {
    if (_mode == INFINIT_LINK_MODE)
    {
      self.user_text.attributedStringValue = _user_hover_str;
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
    if (_mode == INFINIT_USER_MODE)
    {
      self.link_text.attributedStringValue = _link_hover_str;
      self.user_text.attributedStringValue = _user_high_str;
      _hover = YES;
    }
    else
    {
      self.user_text.attributedStringValue = _user_norm_str;
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

//- Infinit Send Button Cell -----------------------------------------------------------------------

@interface NSButtonCell(Private)
- (void)_updateMouseTracking;
@end

@implementation InfinitSendButtonCell
{
@private
  BOOL _hover;
}

// Override private mouse tracking function to ensure that we get mouseEntered/Exited events.
- (void)_updateMouseTracking
{
  [super _updateMouseTracking];
  if (self.controlView != nil && [self.controlView respondsToSelector:@selector(_setMouseTrackingForCell:)])
  {
    [self.controlView performSelector:@selector(_setMouseTrackingForCell:) withObject:self];
  }
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  _hover = YES;
  [self.controlView setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  _hover = NO;
  [self.controlView setNeedsDisplay:YES];
}

- (NSRect)drawTitle:(NSAttributedString*)title
          withFrame:(NSRect)frame
             inView:(NSView*)controlView
{
  if (![self isEnabled])
  {
    return [super drawTitle:[[NSAttributedString alloc] initWithString:self.attributedTitle.string
                                                            attributes:self.disabled_attrs]
                  withFrame:frame inView:controlView];
  }

  return [super drawTitle:title withFrame:frame inView:controlView];
}

- (NSBezierPath*)buttonBezierForFrame:(NSRect)frame
{
  CGFloat corner_rad = 3.0;
  NSBezierPath* res = [NSBezierPath bezierPath];
  [res moveToPoint:NSMakePoint(0.0, 0.0)];
  [res lineToPoint:NSMakePoint(frame.size.width, 0.0)];
  [res lineToPoint:NSMakePoint(frame.size.width, frame.size.height - corner_rad)];
  [res lineToPoint:NSMakePoint(frame.size.width - corner_rad, frame.size.height)];
  [res appendBezierPathWithArcWithCenter:NSMakePoint(frame.size.width - corner_rad, frame.size.width - corner_rad)
                                  radius:corner_rad
                              startAngle:90.0
                                endAngle:270.0
                               clockwise:YES];
  [res lineToPoint:NSMakePoint(0.0, frame.size.height)];
  [res closePath];
  return res;
}

- (void)drawBezelWithFrame:(NSRect)frame
                    inView:(NSView*)controlView
{
  NSBezierPath* bg = [self buttonBezierForFrame:frame];
  if ([self isEnabled] && _hover && ![self isHighlighted])
    [IA_RGBA_COLOUR(255, 255, 255, 0.1) set];
  else if ([self isEnabled] && [self isHighlighted])
    [IA_RGBA_COLOUR(0, 0, 0, 0.1) set];
  else
    [[NSColor clearColor] set];
  [bg fill];
  [IA_RGB_COLOUR(196, 54, 55) set];
  NSRect line = NSMakeRect(frame.origin.x, 0.0, 1.0, NSHeight(frame));
  NSRectFill(line);
}

@end

//- Controller -------------------------------------------------------------------------------------

@interface InfinitSendViewController ()
@end

@implementation InfinitSendViewController
{
@private
  __weak id<InfinitSendViewProtocol> _delegate;

  IAUserSearchViewController* _search_controller;
  InfinitSendNoteViewController* _note_controller;
  InfinitSendFilesViewController* _files_controller;

  NSArray* _recipient_list;
  NSString* _note;

  BOOL _for_link;

  InfinitTooltipViewController* _tooltip;

  NSAttributedString* _send_str;
  NSAttributedString* _link_str;

  CGFloat _last_search_height;
  CGFloat _last_files_height;
}

static NSDictionary* _send_btn_disabled_attrs = nil;

- (id)initWithDelegate:(id<InfinitSendViewProtocol>)delegate
  withSearchController:(IAUserSearchViewController*)search_controller
               forLink:(BOOL)for_link;
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _for_link = for_link;
    _delegate = delegate;
    _last_search_height = 45.0;
    _last_files_height = 197.0;

    _search_controller = search_controller;
    [_search_controller setDelegate:self];
    _note_controller = [[InfinitSendNoteViewController alloc] initWithDelegate:self];
    _files_controller = [[InfinitSendFilesViewController alloc] initWithDelegate:self];
    [self.user_link_view setDelegate:self];
    NSFont* send_btn_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Montserrat"
                                                                       traits:(NSUnboldFontMask|NSUnitalicFontMask)
                                                                       weight:3
                                                                         size:13.0];
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSCenterTextAlignment;
    NSShadow* shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = NSMakeSize(0.0, -1.0);
    NSDictionary* attrs = [IAFunctions textStyleWithFont:send_btn_font
                                          paragraphStyle:para
                                                  colour:IA_GREY_COLOUR(255)
                                                  shadow:shadow];
    _send_str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"SEND", nil)
                                                attributes:attrs];
    _link_str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"GET A LINK", nil)
                                                attributes:attrs];
    if (_send_btn_disabled_attrs == nil)
    {
      _send_btn_disabled_attrs = [IAFunctions textStyleWithFont:send_btn_font
                                                 paragraphStyle:para
                                                         colour:IA_RGBA_COLOUR(255, 255, 255, 0.5)
                                                         shadow:shadow];
    }
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  _files_controller = nil;
  _note_controller = nil;
  _search_controller = nil;
  _tooltip = nil;
}

- (void)awakeFromNib
{
  [self.send_button.cell setDisabled_attrs:_send_btn_disabled_attrs];
  [self.search_view addSubview:_search_controller.view];
  [self.search_view addConstraints:[NSLayoutConstraint
                                    constraintsWithVisualFormat:@"V:|[search_view]|"
                                    options:0
                                    metrics:nil
                                    views:@{@"search_view": _search_controller.view}]];
  [self.note_view addSubview:_note_controller.view];
  [self.note_view addConstraints:[NSLayoutConstraint
                                  constraintsWithVisualFormat:@"V:|[note_view]|"
                                  options:0
                                  metrics:nil
                                  views:@{@"note_view": _note_controller.view}]];
  [self.files_view addSubview:_files_controller.view];
  [self.files_view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|[files_view]|"
                                   options:0
                                   metrics:nil
                                   views:@{@"files_view": _files_controller.view}]];
}

- (void)loadView
{
  [super loadView];
  [self.user_link_view setDelegate:self];
  [self setSendButtonState];
  if (_for_link)
  {
    [self.user_link_view setupViewForMode:INFINIT_LINK_MODE];
    self.send_button.attributedTitle = _link_str;
    self.send_button.toolTip = NSLocalizedString(@"Get a link", nil);
    _search_controller.link_mode = YES;
    [self performSelector:@selector(delayedCursorInNote) withObject:nil afterDelay:0.2];
    self.button_width.constant = _link_str.size.width + 40.0;
  }
  else
  {
    [self.user_link_view setupViewForMode:INFINIT_USER_MODE];
    self.send_button.attributedTitle = _send_str;
    self.send_button.toolTip = NSLocalizedString(@"Send to someone", nil);
    _search_controller.link_mode = NO;
    [self performSelector:@selector(delayedCursorInSearch) withObject:nil afterDelay:0.2];
    self.button_width.constant = _send_str.size.width + 40.0;
  }
  // Onboarding
  InfinitOnboardingState onboarding_state = [_delegate onboardingState:self];
  if (onboarding_state == INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION)
  {
    [self performSelector:@selector(delayedOnboardSendFilesNoDestination) withObject:nil afterDelay:0.5];
  }
  else if (onboarding_state == INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION)
  {
    [self performSelector:@selector(delayedOnboardSendNoFilesNoDestination) withObject:nil afterDelay:0.5];
  }
  else if (onboarding_state == INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION)
  {
    [self performSelector:@selector(delayedOnboardSendNoFilesDestination) withObject:nil afterDelay:0.5];
  }
  else if (onboarding_state == INFINIT_ONBOARDING_SEND_FILES_DESTINATION)
  {
    [self performSelector:@selector(delayedOnboardSendFilesDestination) withObject:nil afterDelay:0.5];
  }
  [_files_controller updateWithFiles:[_delegate sendViewWantsFileList:self]];
}

- (void)aboutToChangeView
{
  [_files_controller stopCalculatingFileSize];
  if (_tooltip != nil)
    [_tooltip close];
  [_search_controller aboutToChangeView];
}

- (void)delayedOnboardSendFilesNoDestination
{
  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  NSString* message = NSLocalizedString(@"Search by name or enter an email address", nil);
  [_tooltip showPopoverForView:_search_controller.search_field
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message
              withPopAnimation:YES
                       forTime:5.0];
}

- (void)delayedOnboardSendNoFilesNoDestination
{
  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  NSString* message = NSLocalizedString(@"Search by name or enter an email address", nil);
  [_tooltip showPopoverForView:_search_controller.search_field
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message
              withPopAnimation:YES
                       forTime:5.0];
}

- (void)delayedOnboardSendNoFilesDestination
{
  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  NSString* message = NSLocalizedString(@"Add some files", nil);
  [_tooltip showPopoverForView:_files_controller.view
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message
              withPopAnimation:YES
                       forTime:5.0];
}

- (void)delayedOnboardSendFilesDestination
{
  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  NSString* message = NSLocalizedString(@"Click here to send", nil);
  [_tooltip showPopoverForView:self.send_button
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message
              withPopAnimation:YES
                       forTime:5.0];
}

- (void)delayedCursorInSearch
{
  [self.view.window makeFirstResponder:_search_controller.search_field];
  [_search_controller.search_field.currentEditor moveToEndOfLine:nil];
}

- (void)delayedCursorInNote
{
  [self.view.window makeFirstResponder:_note_controller.note_field];
  [_note_controller.note_field.currentEditor moveToEndOfLine:nil];
}

- (void)setSendButtonState
{
  if ([self inputsGood])
    [self.send_button setEnabled:YES];
  else
    [self.send_button setEnabled:NO];
}

- (void)filesUpdated
{
  NSArray* files = [_delegate sendViewWantsFileList:self];
  [_files_controller updateWithFiles:files];
  [self setSendButtonState];

  if (files.count > 0)
  {
    if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION)
    {
      [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION];
      [_tooltip close];
      [self performSelector:@selector(delayedOnboardSendFilesNoDestination) withObject:nil afterDelay:0.5];
    }
    else if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION)
    {
      [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_FILES_DESTINATION];
      [_tooltip close];
      [self performSelector:@selector(delayedOnboardSendFilesDestination) withObject:nil afterDelay:0.5];
    }
  }
  else
  {
    if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION)
    {
      [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION];
      [_tooltip close];
      [self performSelector:@selector(delayedOnboardSendNoFilesNoDestination) withObject:nil afterDelay:0.5];
    }
    else if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_SEND_FILES_DESTINATION)
    {
      [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION];
      [_tooltip close];
      [self performSelector:@selector(delayedOnboardSendNoFilesDestination) withObject:nil afterDelay:0.5];
    }
  }
}

- (BOOL)inputsGood
{
  NSArray* files = [_delegate sendViewWantsFileList:self];
  if (files.count == 0)
    return NO;

  _note = _note_controller.note;
  if (_note.length > 100)
    _note = [_note substringWithRange:NSMakeRange(0, 100)];

  if (self.user_link_view.mode == INFINIT_USER_MODE)
  {
    NSMutableArray* recipients = [NSMutableArray arrayWithArray:[_search_controller recipientList]];
    if (recipients.count == 0)
      return NO;

    _recipient_list = [NSArray arrayWithArray:recipients];

    for (id object in _recipient_list)
    {
      if ([object isKindOfClass:NSString.class] && ![object isEmail] &&
          ![object isKindOfClass:InfinitUser.class])
      {
        return NO;
      }
    }

    return YES;
  }
  else
  {
    return YES;
  }
}

- (void)doSend
{
  if (self.user_link_view.mode == INFINIT_USER_MODE)
  {
    NSMutableArray* destinations = [NSMutableArray array];
    for (id element in _recipient_list)
    {
      if ([element isKindOfClass:InfinitSearchRowModel.class])
      {
        [destinations addObject:[element destination]];
      }
      else if ([element isKindOfClass:NSString.class])
      {
        [destinations addObject:element];
      }
    }
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_SEND_CREATE_TRANSACTION];
    NSArray* transaction_ids = [_delegate sendView:self
                                    wantsSendFiles:[_delegate sendViewWantsFileList:self]
                                           toUsers:destinations
                                       withMessage:_note];
    if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_SEND_FILES_DESTINATION)
    {
      [_delegate sendView:self wantsSetOnboardingSendTransactionId:transaction_ids[0]];
      [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_FILE_SENDING];
    }
  }
  else
  {
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_SEND_CREATE_LINK];
    NSNumber* transaction_id = [_delegate sendView:self
                                   wantsCreateLink:[_delegate sendViewWantsFileList:self]
                                       withMessage:_note];
    (void)transaction_id;
  }
}

//- User Interaction -------------------------------------------------------------------------------

- (IBAction)sendButtonClicked:(NSButton*)sender
{
  if ([self inputsGood])
    [self doSend];
}

- (IBAction)cancelButtonClicked:(NSButton*)sender
{
  CGFloat min_search_height = NSHeight(_search_controller.search_box_view.frame);
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    if (self.search_constraint.constant > min_search_height)
    {
      [self.content_height_constraint.animator setConstant:min_search_height];
      [self.search_constraint.animator setConstant:min_search_height];
    }
    else
    {
      [self.main_view removeConstraint:self.content_height_constraint];
      self.content_height_constraint = nil;
      [self.files_constraint.animator setConstant:50.0];
      [self.note_constraint.animator setConstant:20.0];
    }
  } completionHandler:^{
    [_delegate sendViewWantsCancel:self];
  }];

  [InfinitMetricsManager sendMetric:INFINIT_METRIC_SEND_TRASH];
  if ([_delegate onboardingSend:self])
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_DONE];
  }
}

//- Note Protocol ----------------------------------------------------------------------------------

- (void)noteViewWantsLoseFocus:(InfinitSendNoteViewController*)sender
{
  if (self.user_link_view.mode == INFINIT_LINK_MODE)
    return;
  [self.view.window makeFirstResponder:_search_controller.search_field];
  [_search_controller.search_field.currentEditor moveToEndOfLine:nil];
  [_search_controller showResults];
}


- (void)noteView:(InfinitSendNoteViewController*)sender
 gotFilesDropped:(NSArray*)files
{
  [_delegate sendView:self hadFilesDropped:files];
}

- (void)noteViewGotFocus:(InfinitSendNoteViewController*)sender
{
  if (self.user_link_view.mode == INFINIT_USER_MODE)
    [_search_controller fixClipView];
}

//- Files Protocol ---------------------------------------------------------------------------------

- (void)fileList:(InfinitSendFilesViewController*)sender
wantsRemoveFileAtIndex:(NSInteger)index
{
  [_delegate sendView:self wantsRemoveFileAtIndex:index];
}

- (void)fileList:(InfinitSendFilesViewController*)sender
wantsChangeHeight:(CGFloat)height
{
  if (height == _last_files_height)
    return;
  CGFloat content_h = (height - _last_files_height) + self.content_height_constraint.constant;
  _last_files_height = height;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     self.content_height_constraint.animator.constant = content_h;
     self.files_constraint.animator.constant = height;
   }
                      completionHandler:^
   {
     self.content_height_constraint.constant = content_h;
     self.files_constraint.constant = height;
   }];
}

- (void)fileListGotAddFilesClicked:(InfinitSendFilesViewController*)sender
{
  [_delegate sendViewWantsOpenFileDialogBox:self];
}

- (void)fileList:(InfinitSendFilesViewController*)sender
 gotFilesDropped:(NSArray*)files
{
  [_delegate sendView:self hadFilesDropped:files];
}

//- Search Protocol --------------------------------------------------------------------------------

- (void)searchView:(IAUserSearchViewController*)sender
   changedToHeight:(CGFloat)search_height
{
  if (_last_search_height == search_height)
    return;

  _last_search_height = search_height;
  BOOL search_mode = NO;
  CGFloat content_height =
    search_height + self.note_constraint.constant + self.files_constraint.constant;
  if (self.content_height_constraint == nil)
  {
    self.content_height_constraint =
      [NSLayoutConstraint constraintWithItem:self.main_view
                                   attribute:NSLayoutAttributeHeight
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:nil
                                   attribute:NSLayoutAttributeNotAnAttribute
                                  multiplier:1.0
                                    constant:NSHeight(self.main_view.frame)];
    [self.main_view addConstraint:self.content_height_constraint];
  }
  if (search_height > NSHeight(_search_controller.search_box_view.frame))
  {
    search_mode = YES;
    [self.main_view removeConstraint:self.search_note_contraint];
  }
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.search_constraint setConstant:search_height];
    if (search_mode)
    {
      CGFloat height = search_height + self.files_constraint.constant;
      self.content_height_constraint.animator.constant = height;
      self.note_view.animator.alphaValue =  0.0f;
    }
    else
    {
      [self.content_height_constraint.animator setConstant:content_height];
      self.note_view.hidden = NO;
      self.files_view.hidden = NO;
      self.note_view.animator.alphaValue = 1.0f;
    }
  }
                      completionHandler:^
  {
    self.note_view.hidden = search_mode;
    CGFloat alpha = search_mode ? 0.0 : 1.0;
    self.note_view.alphaValue = alpha;
    self.search_constraint.constant = search_height;
    CGFloat height = search_height + self.files_constraint.constant;
    self.content_height_constraint.constant = search_mode ? height : content_height;
    if (!search_mode && self.search_note_contraint == nil)
    {
      self.search_note_contraint = [NSLayoutConstraint constraintWithItem:self.search_view
                                                                attribute:NSLayoutAttributeBottom
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.note_view
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0
                                                                 constant:0.0];
      [self.main_view addConstraint:self.search_note_contraint];
    }
  }];
}

- (void)searchViewWantsLoseFocus:(IAUserSearchViewController*)sender
{
  [self.view.window makeFirstResponder:_note_controller.note_field];
  [_note_controller.note_field.currentEditor moveToEndOfLine:nil];
}

- (void)searchViewInputsChanged:(IAUserSearchViewController*)sender
{
  // Change the onboarding state according to how the recipients have changed.
  InfinitOnboardingState onboarding_state = [_delegate onboardingState:self];
  NSArray* recipients = [_search_controller recipientList];
  if (recipients.count > 0)
  {
    if (onboarding_state == INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION)
    {
      [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION];
      [_tooltip close];
      [self performSelector:@selector(delayedOnboardSendNoFilesDestination) withObject:nil afterDelay:0.5];
    }
    else if (onboarding_state == INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION)
    {
      [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_FILES_DESTINATION];
      [_tooltip close];
      [self performSelector:@selector(delayedOnboardSendFilesDestination) withObject:nil afterDelay:0.5];
    }
  }
  else
  {
    if (onboarding_state == INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION)
    {
      [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION];
      [_tooltip close];
      [self performSelector:@selector(delayedOnboardSendNoFilesNoDestination) withObject:nil afterDelay:0.5];
    }
    else if (onboarding_state == INFINIT_ONBOARDING_SEND_FILES_DESTINATION)
    {
      [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION];
      [_tooltip close];
      [self performSelector:@selector(delayedOnboardSendFilesNoDestination) withObject:nil afterDelay:0.5];
    }
  }
  [self setSendButtonState];
}

- (void)searchViewGotWantsSend:(IAUserSearchViewController*)sender
{
  if ([self inputsGood])
    [self doSend];
}

- (void)delayedClose
{
  [_delegate sendViewWantsClose:self];
}

- (BOOL)searchViewGotEscapePressedShrink:(IAUserSearchViewController*)sender
{
  if (self.search_constraint.constant == NSHeight(_search_controller.search_box_view.frame))
  {
    [self performSelector:@selector(delayedClose) withObject:nil afterDelay:0.0];
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_SEND_TRASH];
    return NO;
  }
  else
  {
    return YES;
  }
}

//- User Link Protocol -----------------------------------------------------------------------------

- (void)gotUserClick:(InfinitSendUserLinkView*)sender
{
  [self.user_link_view setMode:INFINIT_USER_MODE];
  self.send_button.attributedTitle = _send_str;
  self.button_width.constant = _send_str.size.width + 40.0;
  self.send_button.toolTip = NSLocalizedString(@"Send", nil);
  _search_controller.link_mode = NO;
  [self.view.window makeFirstResponder:_search_controller.search_field];
  [self setSendButtonState];
}

- (void)gotLinkClick:(InfinitSendUserLinkView*)sender
{
  [self.user_link_view setMode:INFINIT_LINK_MODE];
  self.send_button.attributedTitle = _link_str;
  self.button_width.constant = _link_str.size.width + 40.0;
  self.send_button.toolTip = NSLocalizedString(@"Get a Link", nil);
  _search_controller.link_mode = YES;
  [self.view.window makeFirstResponder:_note_controller.note_field];
  [_note_controller.note_field.currentEditor moveToEndOfLine:nil];
  [self setSendButtonState];
}

//- Drop View Protocol -----------------------------------------------------------------------------


- (void)gotDroppedFiles:(NSArray*)files
{
  [_delegate sendView:self hadFilesDropped:files];
}

@end
