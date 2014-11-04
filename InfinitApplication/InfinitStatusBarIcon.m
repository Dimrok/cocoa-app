//
//  InfinitStatusBarIcon.m
//  InfinitApplication
//
//  Created by Christopher Crone on 02/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitStatusBarIcon.h"
#import "InfinitMetricsManager.h"
#import "InfinitTooltipViewController.h"

#import "NSStatusBarButtonCell+ForciblyHighlighted.h"

#import <QuartzCore/QuartzCore.h>

@implementation InfinitStatusBarIcon
{
@private
  __weak id<InfinitStatusBarIconProtocol> _delegate;

  NSStatusItem* _status_item;

  NSImage* _normal_icon;
  NSImage* _inverted_icon;
  NSMutableArray* _animated_icon;
  NSTimer* _animation_timer;

  NSArray* _drag_types;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;
    _hidden = NO;
    _status_item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_status_item.button setButtonType:NSToggleButton];
    _status_item.button.toolTip = NSLocalizedString(@"Offline!", nil);
    _status_item.button.appearsDisabled = YES;
    _status_item.button.ignoresMultiClick = YES;
    _status_item.button.target = self;
    _status_item.button.action = @selector(iconClicked:);
    _normal_icon = [IAFunctions imageNamed:@"icon-menu-bar-yosemite"];
    _normal_icon.template = YES;
    _status_item.button.image = _normal_icon;
    _status_item.button.alternateImage = _normal_icon;
    _drag_types = @[NSFilenamesPboardType];
    [_status_item.button.window registerForDraggedTypes:_drag_types];
    _status_item.button.window.delegate = self;
    _animated_icon = [NSMutableArray array];
    for (int i = 1; i <= 18; i++)
    {
      NSString* image_name = [NSString stringWithFormat:@"icon-menu-bar-animated-black-%d", i];
      NSImage* image = [IAFunctions imageNamed:image_name];
      image.template = YES;
      [_animated_icon addObject:image];
    }
  }
  return self;
}

- (void)dealloc
{
  [_animation_timer invalidate];
  _animation_timer = nil;
  [_status_item.button.window unregisterDraggedTypes];
}

//- Drag Operations --------------------------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if ([paste_board availableTypeFromArray:_drag_types])
  {
    [_delegate statusBarIconDragEntered:self];
    return NSDragOperationCopy;
  }
  return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if (![paste_board availableTypeFromArray:_drag_types])
    return NO;

  NSArray* files = [paste_board propertyListForType:NSFilenamesPboardType];

  if (files.count > 0)
  {
    [_delegate statusBarIconDragDrop:self withFiles:files];
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_DROP_STATUS_BAR_ICON];
  }
  return YES;
}

//- General Functions ------------------------------------------------------------------------------

- (void)setConnected:(gap_UserStatus)connected
{
  _connected = connected;
  if (_connected == gap_user_status_online)
  {
    _status_item.button.appearsDisabled = NO;
    _status_item.button.toolTip = NSLocalizedString(@"Online, send something!", nil);
  }
  else
  {
    _status_item.button.appearsDisabled = YES;
    _status_item.button.toolTip = NSLocalizedString(@"Offline!", nil);
  }
}

- (NSRect)frame
{
  return [_status_item.button.window convertRectToScreen:_status_item.button.frame];
}

- (void)setHidden:(BOOL)hidden
{
  if (_hidden == hidden)
    return;
  _hidden = hidden;
  _status_item.button.hidden = _hidden;
}

- (void)setNumber:(NSUInteger)number
{
  _number = number;
  if (_number == 0)
  {
    _status_item.button.imagePosition = NSImageOnly;
    _status_item.button.title = @"";
  }
  else if (_number < 99)
  {
    _status_item.button.imagePosition = NSImageLeft;
    _status_item.button.title = [NSString stringWithFormat:@" %lu", _number];
  }
  else
  {
    _status_item.button.imagePosition = NSImageLeft;
    _status_item.button.title = @" +";
  }
}

- (void)setOpen:(BOOL)open
{
  _open = open;
  if (_open)
  {
    _status_item.button.state = NSOnState;
    [_status_item.button.cell setForciblyHighlighted:YES];
  }
  else
  {
    _status_item.button.state = NSOffState;
    [_status_item.button.cell setForciblyHighlighted:NO];
  }
}

- (void)setTransferring:(BOOL)transferring
{
  if (_transferring == transferring)
    return;
  _transferring = transferring;
  if (_transferring)
  {
    NSMutableDictionary* frame_number =
      [NSMutableDictionary dictionaryWithDictionary:@{@"frame": @0}];

    _animation_timer = [NSTimer timerWithTimeInterval:1/18.0
                                               target:self
                                             selector:@selector(updateButtonImage:)
                                             userInfo:frame_number
                                              repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_animation_timer forMode:NSDefaultRunLoopMode];
  }
  else
  {
    [_animation_timer invalidate];
    _animation_timer = nil;
    _status_item.button.image = _normal_icon;
  }
}

- (void)updateButtonImage:(NSTimer*)timer
{
  NSMutableDictionary* frame_number = timer.userInfo;
  NSUInteger frame = [frame_number[@"frame"] unsignedIntegerValue];
  _status_item.button.image = _animated_icon[frame];
  if (frame < _animated_icon.count - 1)
    frame++;
  else
    frame = 0;
  [frame_number setValue:[NSNumber numberWithUnsignedInteger:frame] forKey:@"frame"];
}

- (NSView*)view
{
  return _status_item.button;
}

//- User Actions -----------------------------------------------------------------------------------

- (void)iconClicked:(id)sender
{
  self.open = !self.open;
  [_delegate statusBarIconClicked:self];
}

@end
