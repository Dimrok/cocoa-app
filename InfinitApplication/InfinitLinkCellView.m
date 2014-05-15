//
//  InfinitLinkCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkCellView.h"

#import "InfinitLinkIconManager.h"

@implementation InfinitLinkCellView
{
@private
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
  _hover = YES;
  self.link.hidden = NO;
  self.clipboard.hidden = NO;
  self.click_count.hidden = YES;
  [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  _hover = NO;
  self.link.hidden = YES;
  self.clipboard.hidden = YES;
  self.click_count.hidden = NO;
  [self setNeedsDisplay:YES];
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

  self.clipboard.normal_image = [IAFunctions imageNamed:@"icon-clipboard"];
  self.clipboard.hover_image = [IAFunctions imageNamed:@"icon-clipboard-hover"];
}

- (void)setupCellWithLink:(InfinitLinkTransaction*)link
{
  _transaction_link = link;
  [self setupButtons];
  self.click_count.count = link.click_count;
  self.icon_view.icon = [InfinitLinkIconManager iconForFilename:link.name];
  self.name.stringValue = link.name;
  if (link.status == gap_transaction_transferring)
  {
    self.progress_indicator.hidden = NO;
    [self setProgress:link.progress.doubleValue];
  }
  else
  {
    self.information.stringValue = [IAFunctions relativeDateOf:link.creation_time];
    self.progress_indicator.hidden = YES;
  }
}

//- Progress Handling ------------------------------------------------------------------------------

- (void)setProgress:(CGFloat)progress
{
  NSString* upload_str = [NSString stringWithFormat:@"%@... (%.0f %%)",
                          NSLocalizedString(@"Uploading", nil), 100 * progress];
  self.information.stringValue = upload_str;
  [self.progress_indicator.animator setDoubleValue:progress];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)linkClicked:(NSButton*)sender
{

}

- (IBAction)clipboardClicked:(NSButton*)sender
{

}

@end
