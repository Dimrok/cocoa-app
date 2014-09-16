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

#import <algorithm>

namespace
{
  const NSTimeInterval kMinimumTimeInterval = std::numeric_limits<NSTimeInterval>::min();
}

//- Link Blur View ---------------------------------------------------------------------------------

@implementation InfinitLinkBlurView

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
    CAGradientLayer* layer = [CAGradientLayer layer];
    layer.frame = self.bounds;
    layer.colors = @[(id)[NSColor clearColor].CGColor, (id)IA_GREY_COLOUR(255).CGColor];
    layer.startPoint = CGPointMake(0.0, 1.0);
    layer.endPoint = CGPointMake(0.25, 1.0);
    self.wantsLayer = YES;
    self.layer.mask = layer;
  }
  return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_GREY_COLOUR(248) set];
  NSRectFill(self.bounds);
}

@end

//- Link Cell View ---------------------------------------------------------------------------------

@implementation InfinitLinkCellView
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitLinkCellProtocol> _delegate;
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
}

- (void)prepareForReuse
{
  _click_count = 0;
  self.buttons_constraint.constant = 317.0;
  self.click_count.hidden = NO;
  self.click_count.alphaValue = 1.0;
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  if (_hover || [_delegate userScrolling:self])
    return;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     _hover = YES;
     context.duration = 0.2;
     [self.click_count.animator setAlphaValue:0.0];
     [self.buttons_constraint.animator setConstant:187.0];
   }
                      completionHandler:^
   {
     self.click_count.animator.alphaValue = 0.0;
     self.click_count.hidden = YES;
     self.buttons_constraint.constant = 187.0;
   }];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  if (_delete_clicks > 0)
  {
    _delete_clicks = 0;
    self.delete_link.normal_image = [IAFunctions imageNamed:@"icon-delete"];
    self.delete_link.hover_image = [IAFunctions imageNamed:@"icon-delete-hover"];
    self.link.alphaValue= 1.0;
    self.clipboard.alphaValue = 1.0;
  }
  [_delegate linkCellLostMouseHover:self];
  if (!_hover)
    return;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.2;
     [self.click_count.animator setAlphaValue:1.0];
     [self.buttons_constraint.animator setConstant:317.0];
   }
                      completionHandler:^
   {
     _hover = NO;
     self.click_count.alphaValue = 1.0;
     self.click_count.hidden = NO;
     self.buttons_constraint.constant = 317.0;
   }];
}

- (void)hideControls
{
  if (!_hover)
    return;
  _hover = NO;
  if (_delete_clicks > 0)
  {
    _delete_clicks = 0;
    self.delete_link.normal_image = [IAFunctions imageNamed:@"icon-delete"];
    self.delete_link.hover_image = [IAFunctions imageNamed:@"icon-delete-hover"];
    self.link.alphaValue= 1.0;
    self.clipboard.alphaValue = 1.0;
  }
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = kMinimumTimeInterval;
    [self.buttons_constraint.animator setConstant:317.0];
    self.click_count.hidden = NO;
    self.click_count.alphaValue = 1.0;
  } completionHandler:nil];
}

- (void)checkMouseInside
{
  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
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
  self.cancel.normal_image = [IAFunctions imageNamed:@"link-icon-cancel"];
  self.cancel.hover_image = [IAFunctions imageNamed:@"link-icon-cancel-hover"];
  self.cancel.toolTip = NSLocalizedString(@"Cancel", nil);

  self.link.normal_image = [IAFunctions imageNamed:@"icon-share"];
  self.link.hover_image = [IAFunctions imageNamed:@"icon-share-hover"];
  self.link.toolTip = NSLocalizedString(@"Open link", nil);

  self.clipboard.normal_image = [IAFunctions imageNamed:@"icon-clipboard"];
  self.clipboard.hover_image = [IAFunctions imageNamed:@"icon-clipboard-hover"];
  self.clipboard.toolTip = NSLocalizedString(@"Copy link", nil);

  self.delete_link.normal_image = [IAFunctions imageNamed:@"icon-delete"];
  self.delete_link.hover_image = [IAFunctions imageNamed:@"icon-delete-hover"];
  self.delete_link.toolTip = NSLocalizedString(@"Delete link", nil);
}

- (void)setupCellWithLink:(InfinitLinkTransaction*)link
              andDelegate:(id<InfinitLinkCellProtocol>)delegate
         withOnlineStatus:(gap_UserStatus)status
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
    [self setProgress:link.progress withAnimation:NO andOnline:status];
  }
  else if (link.status == gap_transaction_on_other_device)
  {
    self.information.stringValue = NSLocalizedString(@"Uploading elsewhere", nil);
  }
  else
  {
    self.progress_indicator.hidden = YES;
    self.information.stringValue = [IAFunctions relativeDateOf:link.modification_time
                                                  longerFormat:YES];
  }
  if (link.status == gap_transaction_transferring || link.status == gap_transaction_on_other_device)
    self.cancel.hidden = NO;
  else
    self.cancel.hidden = YES;
}

//- Progress Handling ------------------------------------------------------------------------------

- (void)setProgress:(CGFloat)progress
{
  [self setProgress:progress withAnimation:YES andOnline:gap_user_status_online];
}

- (void)setProgress:(CGFloat)progress
      withAnimation:(BOOL)animate
          andOnline:(gap_UserStatus)status
{
  NSString* upload_str;
  if (status == gap_user_status_online)
  {
    upload_str = [NSString stringWithFormat:@"%@... (%.0f %%)",
                  NSLocalizedString(@"Uploading", nil), 100 * progress];
  }
  else
  {
    upload_str = NSLocalizedString(@"No connection. Upload paused.", nil);
  }
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

- (IBAction)cancelClicked:(NSButton*)sender
{
  [_delegate linkCell:self gotCancelForLink:_transaction_link];
}

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

- (IBAction)deleteLinkClicked:(NSButton*)sender
{
  _delete_clicks++;
  if (_delete_clicks < 2)
  {
    self.delete_link.normal_image = [IAFunctions imageNamed:@"icon-delete-confirm"];
    self.delete_link.hover_image = [IAFunctions imageNamed:@"icon-delete-confirm"];
    self.delete_link.image = [IAFunctions imageNamed:@"icon-delete-confirm"];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
    {
      [self.link.animator setAlphaValue:0.0];
      [self.clipboard.animator setAlphaValue:0.0];
    } completionHandler:nil];
  }
  [_delegate linkCell:self gotDeleteForLink:_transaction_link];
}

@end
