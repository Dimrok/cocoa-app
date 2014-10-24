//
//  InfinitSendFileView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 14/10/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendFileView.h"

#import <QuartzCore/QuartzCore.h>

@implementation InfinitSendFileView
{
@private
  NSTrackingArea* _tracking_area;
}

- (void)dealloc
{
  _tracking_area = nil;
}

- (void)setAdd_files_placeholder:(BOOL)add_files_placeholder
{
  _add_files_placeholder = add_files_placeholder;
  [self.icon_button.cell setImageDimsWhenDisabled:NO];
  if (_add_files_placeholder)
  {
    self.remove_button.hidden = YES;
    self.icon_button.enabled = YES;
  }
  else
  {
    self.remove_button.alphaValue = 0.0;
    self.remove_button.hidden = NO;
    self.icon_button.enabled = NO;
  }
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
  if (_add_files_placeholder)
    return;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    [self.remove_button.animator setAlphaValue:1.0];
  } completionHandler:^{
    self.remove_button.alphaValue = 1.0;
  }];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  if (_add_files_placeholder)
    return;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     [self.remove_button.animator setAlphaValue:0.0];
   } completionHandler:^{
     self.remove_button.alphaValue = 0.0;
   }];
}

+ (id)defaultAnimationForKey:(NSString*)key
{
  if ([key isEqualToString:@"hover"])
    return [CABasicAnimation animation];

  return [super defaultAnimationForKey:key];
}

@end
