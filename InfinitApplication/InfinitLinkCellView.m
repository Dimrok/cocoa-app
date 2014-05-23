//
//  InfinitLinkCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkCellView.h"

#import "InfinitMetricsManager.h"
#import "InfinitLinkIconManager.h"

#import <QuartzCore/QuartzCore.h>

@implementation InfinitLinkCellView
{
@private
  id<InfinitLinkCellProtocol> _delegate;
  NSTrackingArea* _tracking_area;
  BOOL _hover;

  InfinitLinkTransaction* _transaction_link;
}

//- Mouse Tracking ---------------------------------------------------------------------------------

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
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     _hover = YES;
     self.link.hidden = NO;
     self.clipboard.hidden = NO;
     context.duration = 0.2;
     context.timingFunction =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
     [self.link.animator setFrameOrigin:NSMakePoint(279.0, 40.0)];
     [self.clipboard.animator setFrameOrigin:NSMakePoint(279.0, 11.0)];
     [self.click_count.animator setAlphaValue:0.0];
   }
                      completionHandler:^
   {
     [self.link setFrameOrigin:NSMakePoint(279.0, 40.0)];
     [self.clipboard setFrameOrigin:NSMakePoint(279.0, 11.0)];
     [self.click_count setAlphaValue:0.0];
     self.click_count.hidden = YES;
     self.link.hidden = NO;
     self.clipboard.hidden = NO;
   }];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    _hover = NO;
    self.click_count.hidden = NO;
    context.duration = 0.2;
    context.timingFunction =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.link.animator setFrameOrigin:NSMakePoint(317.0, 25.0)];
    [self.clipboard.animator setFrameOrigin:NSMakePoint(317.0, 25.0)];
    [self.click_count.animator setAlphaValue:1.0];

  }
                      completionHandler:^
  {
    [self.link setFrameOrigin:NSMakePoint(317.0, 25.0)];
    [self.clipboard setFrameOrigin:NSMakePoint(317.0, 25.0)];
    [self.click_count setAlphaValue:1.0];
    self.click_count.hidden = NO;
    self.link.hidden = YES;
    self.clipboard.hidden = YES;
  }];
}

//- Drawing ----------------------------------------------------------------------------------------

- (BOOL)isOpaque
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_GREY_COLOUR(248) set];
  NSRectFill(self.bounds);
  [IA_GREY_COLOUR(230) set];
  NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 1.0,
                                                                        NSWidth(self.bounds), 1.0)];
  [dark_line fill];
  [IA_GREY_COLOUR(255) set];
  NSBezierPath* light_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0,
                                                                         NSWidth(self.bounds), 1.0)];
  [light_line fill];
}

//- Setup ------------------------------------------------------------------------------------------

- (void)setupButtons
{
  self.link.normal_image = [IAFunctions imageNamed:@"icon-share"];
  self.link.hover_image = [IAFunctions imageNamed:@"icon-share-hover"];
  self.link.toolTip = NSLocalizedString(@"Open link", nil);

  self.clipboard.normal_image = [IAFunctions imageNamed:@"icon-clipboard"];
  self.clipboard.hover_image = [IAFunctions imageNamed:@"icon-clipboard-hover"];
  self.clipboard.toolTip = NSLocalizedString(@"Copy link", nil);
}

- (void)setupCellWithLink:(InfinitLinkTransaction*)link
              andDelegate:(id<InfinitLinkCellProtocol>)delegate
{
  _delegate = delegate;
  _transaction_link = link;
  [self setupButtons];
  self.click_count.count = link.click_count;
  self.icon_view.icon = [InfinitLinkIconManager iconForFilename:link.name];
  self.name.stringValue = link.name;
  if (link.status == gap_transaction_transferring)
  {
    self.progress_indicator.hidden = NO;
    [self setProgress:link.progress];
  }
  else
  {
    self.information.stringValue = [IAFunctions relativeDateOf:link.modification_time
                                                  longerFormat:YES];
    self.progress_indicator.hidden = YES;
  }
}

//- Progress Handling ------------------------------------------------------------------------------

- (void)setProgress:(CGFloat)progress
{
  [self setProgress:progress withAnimation:YES];
}

- (void)setProgress:(CGFloat)progress
      withAnimation:(BOOL)animate
{
  NSString* upload_str = [NSString stringWithFormat:@"%@... (%.0f %%)",
                          NSLocalizedString(@"Uploading", nil), 100 * progress];
  self.information.stringValue = upload_str;
  if (animate)
  {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
    {
      context.duration = 1.0;
      [self.progress_indicator.animator setDoubleValue:progress];
    }
                        completionHandler:^
    {
      self.progress_indicator.doubleValue = progress;
    }];
  }
  else
  {
    self.progress_indicator.doubleValue = progress;
  }
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)linkClicked:(NSButton*)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:_transaction_link.url_link]];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_OPEN_LINK];
}

- (IBAction)clipboardClicked:(NSButton*)sender
{
  NSPasteboard* paste_board = [NSPasteboard generalPasteboard];
  [paste_board declareTypes:@[NSStringPboardType] owner:nil];
  [paste_board setString:_transaction_link.url_link forType:NSStringPboardType];
  [_delegate linkCell:self gotCopyToClipboardForLink:_transaction_link];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_COPY_LINK];
}

@end
