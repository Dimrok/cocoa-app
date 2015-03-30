//
//  IAStatusBarIcon.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAStatusBarIcon.h"
#import "IAFunctions.h"
#import "InfinitMetricsManager.h"
#import "InfinitTooltipViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitLinkTransactionManager.h>
#import <Gap/infinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitUserManager.h>

#import <algorithm>

namespace
{
  const NSTimeInterval kMinimumTimeInterval = std::numeric_limits<NSTimeInterval>::min();
}

typedef enum __IAStatusBarIconStatus
{
  STATUS_BAR_ICON_NORMAL = 0,
  STATUS_BAR_ICON_FIRE,
  STATUS_BAR_ICON_CLICKED,
  STATUS_BAR_ICON_NO_CONNECTION,
  STATUS_BAR_ICON_ANIMATED,
  STATUS_BAR_ICON_FIRE_ANIMATED,
  STATUS_BAR_ICON_LOGGING_IN,
  STATUS_BAR_ICON_LINK,
} IAStatusBarIconStatus;

typedef enum __InfinitStatusBarIconColour
{
  STATUS_BAR_ICON_COLOUR_BLACK = 0,
  STATUS_BAR_ICON_COLOUR_RED = 1,
} InfinitStatusBarIconColour;

@interface IAStatusBarIcon ()

@property (nonatomic, readwrite) BOOL connected;
@property (nonatomic, readwrite) BOOL fire;
@property (nonatomic, readwrite) NSUInteger number;
@property (nonatomic, readwrite) BOOL transferring;

@end

@implementation IAStatusBarIcon
{
@private
  id _delegate;
  NSArray* _drag_types;
  NSImage* _icon[8];
  NSImageView* _icon_view;
  BOOL _is_highlighted;
  BOOL _connected;
  NSStatusItem* _status_item;
  CGFloat _length;
  
  IAStatusBarIconStatus _current_mode;
  NSArray* _black_animated_images;
  NSArray* _red_animated_images;

  NSTrackingArea* _tracking_area;
  InfinitTooltipViewController* _tooltip;

  NSAttributedString* _notifications_str;

  NSTimer* _animation_timer;
  BOOL _animating;
}

@synthesize isHighlighted = _is_highlighted;

static NSDictionary* _red_style;
static NSDictionary* _black_style;
static NSDictionary* _white_style;
static NSDictionary* _grey_style;

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
  if (self = [super initWithFrame:frame])
  {
    [self addSubview:_icon_view];
    _drag_types = @[NSFilenamesPboardType];
    _current_mode = STATUS_BAR_ICON_NO_CONNECTION;
    [self registerForDraggedTypes:_drag_types];
    [self setWantsLayer:YES];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  _tracking_area = nil;
  [self unregisterDraggedTypes];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [_animation_timer invalidate];
  _animation_timer = nil;
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
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

- (id)initWithDelegate:(id<IAStatusBarIconProtocol>)delegate
            statusItem:(NSStatusItem*)status_item
{
  if (self = [super init])
  {
    _delegate = delegate;
    [self setUpAnimatedIcons];
    _icon[STATUS_BAR_ICON_NORMAL] = [IAFunctions imageNamed:@"icon-menu-bar-active"];
    _icon[STATUS_BAR_ICON_FIRE] = [IAFunctions imageNamed:@"icon-menu-bar-fire"];
    _icon[STATUS_BAR_ICON_CLICKED] = [IAFunctions imageNamed:@"icon-menu-bar-clicked"];
    _icon[STATUS_BAR_ICON_NO_CONNECTION] = [IAFunctions
                                            imageNamed:@"icon-menu-bar-inactive"];
    _icon[STATUS_BAR_ICON_LINK] = [IAFunctions imageNamed:@"icon-menu-bar-link"];
    
    _icon_view = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 16.0, 16.0)];
    _icon_view.image = _icon[STATUS_BAR_ICON_NO_CONNECTION];
    // Must unregister drags from image view so that they are passed to parent view.
    [_icon_view unregisterDraggedTypes];
    
    _status_item = status_item;
    _length = _icon[STATUS_BAR_ICON_NORMAL].size.width + 15.0;
    CGFloat height = [[NSStatusBar systemStatusBar] thickness];
    NSRect rect = NSMakeRect(0.0, 0.0, _length, height);
    self = [self initWithFrame:rect];

    if (_red_style == nil)
    {
      NSFont* font = [NSFont systemFontOfSize:15.0];
      _white_style = [IAFunctions textStyleWithFont:font
                                     paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                             colour:IA_GREY_COLOUR(255.0)
                                             shadow:nil];
      _red_style = [IAFunctions textStyleWithFont:font
                                   paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                           colour:IA_RGB_COLOUR(221.0, 0.0, 0.0)
                                           shadow:nil];
      _black_style = [IAFunctions textStyleWithFont:font
                                     paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                             colour:IA_GREY_COLOUR(32.0)
                                             shadow:nil];
      _grey_style = [IAFunctions textStyleWithFont:font
                                    paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                            colour:IA_GREY_COLOUR(93.0)
                                            shadow:nil];
    }
    _tooltip = [[InfinitTooltipViewController alloc] init];
    _animating = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStatusChanged:)
                                                 name:INFINIT_CONNECTION_STATUS_CHANGE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(linkTransactionUpdated:)
                                                 name:INFINIT_NEW_LINK_TRANSACTION_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(linkTransactionUpdated:)
                                                 name:INFINIT_LINK_TRANSACTION_STATUS_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerTransactionUpdated:)
                                                 name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerTransactionUpdated:)
                                                 name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willLogout)
                                                 name:INFINIT_WILL_LOGOUT_NOTIFICATION
                                               object:nil];
  }
  return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
  if (_is_highlighted)
  {
    NSRect rect;
    [[NSColor selectedMenuItemColor] set];
    // WORKAROUND: Highlighting of icon on non-retina screens is broken
    if ([[NSScreen mainScreen] backingScaleFactor] == 1.0 && [IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_10)
    {
      rect = NSMakeRect(self.frame.origin.x,
                        self.frame.origin.y + 1.0,
                        NSWidth(self.bounds),
                        NSHeight(self.bounds) - 1.0);
    }
    else
    {
      rect = self.frame;
    }
    NSRectFill(rect);
  }
  
  switch (_current_mode)
  {
    case STATUS_BAR_ICON_CLICKED:
      _icon_view.image = _icon[STATUS_BAR_ICON_CLICKED];
      break;
    case STATUS_BAR_ICON_LOGGING_IN:
      _icon_view.image = _icon[STATUS_BAR_ICON_NO_CONNECTION];
      break;
    case STATUS_BAR_ICON_NO_CONNECTION:
      _icon_view.image = _icon[STATUS_BAR_ICON_NO_CONNECTION];
      break;
    case STATUS_BAR_ICON_FIRE_ANIMATED:
      // Don't set icon here as the animation changes the icon.
      break;
    case STATUS_BAR_ICON_ANIMATED:
      // Don't set icon here as the animation changes the icon.
      break;
    case STATUS_BAR_ICON_FIRE:
      _icon_view.image = _icon[STATUS_BAR_ICON_FIRE];
      break;
    case STATUS_BAR_ICON_NORMAL:
      _icon_view.image = _icon[STATUS_BAR_ICON_NORMAL];
      break;
    case STATUS_BAR_ICON_LINK:
      _icon_view.image = _icon[STATUS_BAR_ICON_LINK];
      break;
  }
  
  CGFloat x;
  if (self.number == 0)
    x = roundf((NSWidth(self.bounds) - NSWidth(_icon_view.frame)) / 2);
  else
    x = round((NSWidth(self.bounds) - NSWidth(_icon_view.frame) - _notifications_str.size.width) / 2.0 - 2.0);
  CGFloat y = roundf((NSHeight(self.bounds) - NSHeight(_icon_view.frame)) / 2.0);
  [_icon_view setFrameOrigin:NSMakePoint(x, y)];
  
  if (self.number > 0)
  {
    [_notifications_str drawAtPoint:NSMakePoint(_length - _notifications_str.size.width - 5.0, 2.0)];
  }
}

- (NSArray*)animationArrayWithColour:(InfinitStatusBarIconColour)colour
{
  NSString* colour_str;
  NSMutableArray* array = [[NSMutableArray alloc] init];
  switch (colour)
  {
    case STATUS_BAR_ICON_COLOUR_BLACK:
      colour_str = @"black";
      break;
    case STATUS_BAR_ICON_COLOUR_RED:
      colour_str = @"red";
      break;
    default:
      colour_str = @"black";
      break;
  }
  for (int i = 1; i <= 18; i++)
  {
    NSString* image_name =
    [NSString stringWithFormat:@"icon-menu-bar-animated-%@-%d", colour_str, i];
    [array addObject:[IAFunctions imageNamed:image_name]];
  }
  return array;
}

- (void)setUpAnimatedIcons
{
  _black_animated_images = [self animationArrayWithColour:STATUS_BAR_ICON_COLOUR_BLACK];
  _red_animated_images = [self animationArrayWithColour:STATUS_BAR_ICON_COLOUR_RED];
}

- (void)showAnimatedIconForMode:(IAStatusBarIconStatus)mode
{
  NSString* colour;
  switch (mode)
  {
    case STATUS_BAR_ICON_ANIMATED:
      colour = @"black";
      break;
    case STATUS_BAR_ICON_FIRE_ANIMATED:
      colour = @"red";
      break;
      
    default:
      return;
  }
  NSMutableDictionary* user_info =
    [NSMutableDictionary dictionaryWithDictionary:@{@"frame": @0, @"colour": colour}];

  if (_animation_timer)
    [_animation_timer invalidate];
  _animation_timer = [NSTimer timerWithTimeInterval:1/18.0
                                             target:self
                                           selector:@selector(updateIconImage:)
                                           userInfo:user_info
                                            repeats:YES];
  [[NSRunLoop mainRunLoop] addTimer:_animation_timer forMode:NSDefaultRunLoopMode];
}

- (void)updateIconImage:(NSTimer*)timer
{
  NSMutableDictionary* user_info = timer.userInfo;
  NSUInteger frame = [user_info[@"frame"] unsignedIntegerValue];
  NSArray* images;
  if ([user_info[@"colour"] isEqualToString:@"red"])
    images = _red_animated_images;
  else
    images = _black_animated_images;
  _icon_view.image = images[frame];
  [self setNeedsDisplay:YES];
  if (frame < images.count - 1)
    frame++;
  else
    frame = 0;
  [user_info setValue:[NSNumber numberWithUnsignedInteger:frame] forKey:@"frame"];
}

//- General Functions ------------------------------------------------------------------------------

- (void)determineCurrentMode
{
  if (!_animating)
  {
    [_animation_timer invalidate];
    _animation_timer = nil;
  }
  IAStatusBarIconStatus last_mode = _current_mode;
  if (_is_highlighted)
  {
    _current_mode = STATUS_BAR_ICON_CLICKED;
  }
  else if (_show_link)
  {
    _current_mode = STATUS_BAR_ICON_LINK;
  }
  else if (!self.connected)
  {
    _current_mode = STATUS_BAR_ICON_NO_CONNECTION;
  }
  else if (self.transferring && self.fire)
  {
    if (_current_mode != STATUS_BAR_ICON_FIRE_ANIMATED)
    {
      _current_mode = STATUS_BAR_ICON_FIRE_ANIMATED;
      [self showAnimatedIconForMode:STATUS_BAR_ICON_FIRE_ANIMATED];
    }
  }
  else if (!self.transferring && self.fire)
  {
    _current_mode = STATUS_BAR_ICON_FIRE;
  }
  else if (self.transferring && !self.fire)
  {
    if (_current_mode != STATUS_BAR_ICON_ANIMATED)
    {
      _current_mode = STATUS_BAR_ICON_ANIMATED;
      [self showAnimatedIconForMode:STATUS_BAR_ICON_ANIMATED];
    }
  }
  else
  {
    _current_mode = STATUS_BAR_ICON_NORMAL;
  }
  [self setNotificationString];
  if (last_mode != _current_mode)
    [self setNeedsDisplay:YES];
}

- (void)setConnected:(BOOL)connected
{
  [_tooltip close];
  _connected = connected;
  _icon_view.alphaValue = 1.0;
  NSString* message;
  if (_connected)
    message = NSLocalizedString(@"Online, send something!", nil);
  else
    message = NSLocalizedString(@"Offline!", nil);
  [self performSelector:@selector(delayedShowPopoverWithMessage:)
             withObject:message
             afterDelay:0.5];
  [self determineCurrentMode];
}

- (void)setHighlighted:(BOOL)is_highlighted
{
  [_tooltip close];
  _is_highlighted = is_highlighted;
  _icon_view.alphaValue = 1.0;
  [self determineCurrentMode];
  // Only send metric when the panel is opened
}

- (void)setNotificationString
{
  NSDictionary* style;
  if (_is_highlighted)
  {
    style = _white_style;
  }
  else if (self.connected && self.fire)
  {
    style = _red_style;
  }
  else if (self.connected && !self.fire)
  {
    style = _black_style;
  }
  else if (!self.connected)
  {
    style = _grey_style;
  }
  NSString* number_str =
  self.number > 99 ? @"+" : [@(self.number) stringValue];
  _notifications_str = [[NSAttributedString alloc] initWithString:number_str
                                                       attributes:style];
}

- (void)setNumber:(NSUInteger)number
{
  _fire = (number > 0);
  _number = number;
  _length = _icon[STATUS_BAR_ICON_NORMAL].size.width + 15.0;
  [self setNotificationString];
  if (self.number > 9)
    _length += _notifications_str.length + 20.0;
  else if (self.number > 0)
    _length += _notifications_str.length + 10.0;
  self.frame = NSMakeRect(0.0, 0.0, _length, [[NSStatusBar systemStatusBar] thickness]);
  [self setNeedsDisplay:YES];
}

- (void)setTransferring:(BOOL)transferring
{
  _animating = transferring;
  _transferring = transferring;
  _icon_view.alphaValue = 1.0;
  [self determineCurrentMode];
}

//- Click Operations -------------------------------------------------------------------------------

- (void)mouseDown:(NSEvent*)theEvent
{
  [_delegate statusBarIconClicked:self];
}

- (void)delayedShowPopoverWithMessage:(NSString*)message
{
  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds) && !_is_highlighted)
  {
    [_tooltip showPopoverForView:self
              withArrowDirection:INPopoverArrowDirectionUp
                     withMessage:message
                withPopAnimation:NO
                         forTime:0.0];
  }
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  if (_is_highlighted)
    return;
  if ([NSEvent modifierFlags] == NSAlternateKeyMask)
  {
    _show_link = YES;
    [self determineCurrentMode];
  }
  NSString* message;
  if (_connected && _show_link)
    message = NSLocalizedString(@"Hold \u2325 and drop files to get a link!", nil);
  else if (_connected)
    message = NSLocalizedString(@"Online, send something!", nil);
  else
    message = NSLocalizedString(@"Offline!", nil);
  [self performSelector:@selector(delayedShowPopoverWithMessage:)
             withObject:message
             afterDelay:1.0];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  [_tooltip close];
  if (_show_link)
  {
    _show_link = NO;
    [self determineCurrentMode];
  }
}

//- Drag Operations --------------------------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
  if ([NSEvent modifierFlags] == NSAlternateKeyMask)
  {
    _show_link = YES;
    [self determineCurrentMode];
  }
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if ([paste_board availableTypeFromArray:_drag_types])
  {
    [_delegate statusBarIconDragEntered:self];
    return NSDragOperationCopy;
  }
  return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
  if (_show_link)
  {
    _show_link = NO;
    [self determineCurrentMode];
  }
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if (![paste_board availableTypeFromArray:_drag_types])
    return NO;
  
  NSArray* files = [paste_board propertyListForType:NSFilenamesPboardType];
  
  if (files.count > 0)
  {
    if (_show_link)
    {
      [_delegate statusBarIconLinkDrop:self withFiles:files];
      [InfinitMetricsManager sendMetric:INFINIT_METRIC_STATUS_ICON_LINK_DROP];
    }
    else
    {
      [_delegate statusBarIconDragDrop:self withFiles:files];
      [InfinitMetricsManager sendMetric:INFINIT_METRIC_DROP_STATUS_BAR_ICON];
    }
  }

  if (_show_link)
  {
    _show_link = NO;
    [self determineCurrentMode];
  }
  
  return YES;
}

#pragma mark - Model Handling

- (void)delayedStatusUpdate
{
  self.number = [InfinitPeerTransactionManager sharedInstance].receivable_transaction_count;
  self.transferring = [InfinitPeerTransactionManager sharedInstance].running_transactions ||
                      [InfinitLinkTransactionManager sharedInstance].running_transactions;
}

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  self.connected = connection_status.status;
  if (connection_status.status)
  {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^
     {
       [self delayedStatusUpdate];
     });
  }
  else if (!connection_status.status && !connection_status.still_trying)
  {
    self.number = 0;
  }
}

- (void)linkTransactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  InfinitLinkTransaction* transaction =
  [[InfinitLinkTransactionManager sharedInstance] transactionWithId:id_];
  if (transaction.status == gap_transaction_transferring)
  {
    self.transferring = YES;
    return;
  }
  self.transferring = [InfinitLinkTransactionManager sharedInstance].running_transactions;
}

- (void)peerTransactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  InfinitPeerTransaction* transaction =
  [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  self.number = [InfinitPeerTransactionManager sharedInstance].receivable_transaction_count;
  if (transaction.status == gap_transaction_transferring)
  {
    self.transferring = YES;
    return;
  }
  self.transferring = [InfinitLinkTransactionManager sharedInstance].running_transactions;
}

- (void)willLogout
{
  self.number = 0;
  self.connected = NO;
}

@end
