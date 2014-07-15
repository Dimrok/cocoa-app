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

@implementation IAStatusBarIcon
{
@private
  id _delegate;
  NSArray* _drag_types;
  NSImage* _icon[8];
  NSImageView* _icon_view;
  BOOL _is_highlighted;
  gap_UserStatus _connected;
  NSInteger _number_of_items;
  NSStatusItem* _status_item;
  CGFloat _length;
  
  IAStatusBarIconStatus _current_mode;
  NSArray* _black_animated_images;
  NSArray* _red_animated_images;

  BOOL _animating;

  NSTrackingArea* _tracking_area;
  InfinitTooltipViewController* _tooltip;

  NSAttributedString* _notifications_str;
}
@synthesize isFire = _is_fire;
@synthesize isHighlighted = _is_highlighted;
@synthesize isLoggingIn = _logging_in;
@synthesize isTransferring = _is_transferring;

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
    _number_of_items = 0;
    _connected = gap_user_status_offline;
    _is_transferring = NO;
    _current_mode = STATUS_BAR_ICON_NO_CONNECTION;
    [self registerForDraggedTypes:_drag_types];
    [self setWantsLayer:YES];
  }
  return self;
}

- (void)dealloc
{
  _tracking_area = nil;
  [self unregisterDraggedTypes];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
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
    if ([[NSScreen mainScreen] backingScaleFactor] == 1.0)
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
  if (_number_of_items == 0)
    x = roundf((NSWidth(self.bounds) - NSWidth(_icon_view.frame)) / 2);
  else
    x = round((NSWidth(self.bounds) - NSWidth(_icon_view.frame) - _notifications_str.size.width) / 2.0 - 2.0);
  CGFloat y = roundf((NSHeight(self.bounds) - NSHeight(_icon_view.frame)) / 2.0);
  [_icon_view setFrameOrigin:NSMakePoint(x, y)];
  
  if (_number_of_items > 0)
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
                   withDuration:(NSTimeInterval)duration
{
  IAStatusBarIconStatus start_mode = mode;
  _animating = YES;
  NSArray* images;
  switch (mode)
  {
    case STATUS_BAR_ICON_ANIMATED:
      images = _black_animated_images;
      break;
    case STATUS_BAR_ICON_FIRE_ANIMATED:
      images = _red_animated_images;
      break;
      
    default:
      return;
  }
  CAKeyframeAnimation* kfa = [CAKeyframeAnimation animation];
  kfa.values = images;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = duration;
     _icon_view.animations = @{@"image": kfa};
     _icon_view.animator.image = images[images.count - 1];
   }
                      completionHandler:^
   {
     _animating = NO;
     if (start_mode == _current_mode)
       [self showAnimatedIconForMode:mode withDuration:duration];
     else
       [self setNeedsDisplay:YES];
   }];
}

//- General Functions ------------------------------------------------------------------------------

- (void)determineCurrentMode
{
  @synchronized(self)
  {
    IAStatusBarIconStatus last_mode = _current_mode;
    // WORKAROUND Stop the animation to avoid spin locks on 10.7/10.8.
    if (_animating)
    {
      [NSObject cancelPreviousPerformRequestsWithTarget:self];
      _animating = NO;
      [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
       {
         context.duration = kMinimumTimeInterval;
       } completionHandler:nil];
    }
    if (_is_highlighted)
    {
      _current_mode = STATUS_BAR_ICON_CLICKED;
    }
    else if (_logging_in)
    {
      _current_mode = STATUS_BAR_ICON_LOGGING_IN;
    }
    else if (_show_link)
    {
      _current_mode = STATUS_BAR_ICON_LINK;
    }
    else if (_connected == gap_user_status_offline)
    {
      _current_mode = STATUS_BAR_ICON_NO_CONNECTION;
    }
    else if (_is_transferring && _is_fire)
    {
      if (_current_mode != STATUS_BAR_ICON_FIRE_ANIMATED)
      {
        _current_mode = STATUS_BAR_ICON_FIRE_ANIMATED;
        [self showAnimatedIconForMode:STATUS_BAR_ICON_FIRE_ANIMATED withDuration:1.0];
      }
    }
    else if (!_is_transferring && _is_fire)
    {
      _current_mode = STATUS_BAR_ICON_FIRE;
    }
    else if (_is_transferring && !_is_fire)
    {
      if (_current_mode != STATUS_BAR_ICON_ANIMATED)
      {
        _current_mode = STATUS_BAR_ICON_ANIMATED;
        [self showAnimatedIconForMode:STATUS_BAR_ICON_ANIMATED withDuration:1.0];
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
}

- (void)setConnected:(gap_UserStatus)connected
{
  [_tooltip close];
  _connected = connected;
  _icon_view.alphaValue = 1.0;
  NSString* message;
  if (_connected == gap_user_status_online)
    message = NSLocalizedString(@"Online, send something!", nil);
  else
    message = NSLocalizedString(@"Offline!", nil);
  [self performSelector:@selector(delayedShowPopoverWithMessage:)
             withObject:message
             afterDelay:0.5];
  [self determineCurrentMode];
}

- (void)setFire:(BOOL)fire
{
  _is_fire = fire;
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

- (void)setLoggingIn:(BOOL)isLoggingIn
{
  _logging_in = isLoggingIn;
  if (_logging_in && !_is_highlighted)
    _icon_view.alphaValue = 0.67;
  else
    _icon_view.alphaValue = 1.0;
  [self determineCurrentMode];
}

- (void)setNotificationString
{
  NSDictionary* style;
  if (_is_highlighted)
  {
    style = _white_style;
  }
  else if (_connected == gap_user_status_online && _is_fire)
  {
    style = _red_style;
  }
  else if (_connected == gap_user_status_online && !_is_fire)
  {
    style = _black_style;
  }
  else if (_connected != gap_user_status_online)
  {
    style = _grey_style;
  }
  NSString* number_str =
  _number_of_items > 99 ? @"+" : [[NSNumber numberWithInteger:_number_of_items] stringValue];
  _notifications_str = [[NSAttributedString alloc] initWithString:number_str
                                                       attributes:style];
}

- (void)setNumberOfItems:(NSInteger)number_of_items
{
  _number_of_items = number_of_items;
  _length = _icon[STATUS_BAR_ICON_NORMAL].size.width + 15.0;
  [self setNotificationString];
  if (_number_of_items > 9)
    _length += _notifications_str.length + 20.0;
  else if (_number_of_items > 0)
    _length += _notifications_str.length + 10.0;
  self.frame = NSMakeRect(0.0, 0.0, _length, [[NSStatusBar systemStatusBar] thickness]);
  [self setNeedsDisplay:YES];
}

- (void)setTransferring:(BOOL)isTransferring
{
  _is_transferring = isTransferring;
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
  if (_connected == gap_user_status_online && _show_link)
    message = NSLocalizedString(@"Hold \u2325 and drop files to get a link!", nil);
  else if (_connected == gap_user_status_online)
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

@end
