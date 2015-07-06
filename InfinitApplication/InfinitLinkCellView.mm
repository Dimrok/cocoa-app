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

#import <Gap/InfinitDataSize.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitTime.h>

#import <QuartzCore/QuartzCore.h>

#import <algorithm>

namespace
{
  const NSTimeInterval kMinimumTimeInterval = std::numeric_limits<NSTimeInterval>::min();
}

#pragma mark - LinkBlurView

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

#pragma mark - LinkCellView

@interface InfinitLinkCellView ()

@property (nonatomic, weak) IBOutlet InfinitLinkFileIconView* icon_view;
@property (nonatomic, weak) IBOutlet NSTextField* name;
@property (nonatomic, weak) IBOutlet NSTextField* information;
@property (nonatomic, weak) IBOutlet InfinitLinkClickCountView* click_count;
@property (nonatomic, weak) IBOutlet IAHoverButton* cancel;
@property (nonatomic, weak) IBOutlet IAHoverButton* link;
@property (nonatomic, weak) IBOutlet IAHoverButton* clipboard;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* buttons_constraint;

@property (nonatomic, weak) IBOutlet InfinitLinkBlurView* blur_view;
@property (nonatomic, weak) IBOutlet InfinitLinkProgressIndicator* progress_indicator;

@property (nonatomic, readonly) dispatch_once_t awake_token;
@property (nonatomic, unsafe_unretained) id<InfinitLinkCellProtocol> delegate;
@property (nonatomic, readonly) BOOL hover;
@property (nonatomic, readonly) NSTrackingArea* tracking_area;
@property (nonatomic, readonly) InfinitLinkTransaction* transaction;

@end

static NSImage* _icon_admin = nil;
static NSImage* _icon_admin_hover = nil;
static NSImage* _icon_cancel = nil;
static NSImage* _icon_cancel_hover = nil;
static NSImage* _icon_clipboard = nil;
static NSImage* _icon_clipboard_hover = nil;
static NSImage* _icon_delete = nil;
static NSImage* _icon_delete_confirm = nil;
static NSImage* _icon_delete_hover = nil;

@implementation InfinitLinkCellView

#pragma mark - Mouse Handling

- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];

  [self addTrackingArea:self.tracking_area];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:self.tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)setButtonsHidden:(BOOL)hidden
     animateWithDuration:(CGFloat)duration
{
  if (self.hover == !hidden && duration != kMinimumTimeInterval)
    return;
  _hover = !hidden;
  if (hidden && self.delete_clicks > 0)
  {
    _delete_clicks = 0;
    self.delete_link.normal_image = _icon_delete;
    self.delete_link.hover_image = _icon_delete_hover;
    self.link.alphaValue= 1.0f;
    self.clipboard.alphaValue = 1.0f;
  }
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = duration;
    self.click_count.animator.alphaValue = (hidden ? 1.0f : 0.0f);
    self.click_count.hidden = !hidden;
    self.buttons_constraint.animator.constant = (hidden ? 0.0f : self.blur_view.bounds.size.width);
  } completionHandler:^
  {
    self.click_count.alphaValue = (hidden ? 1.0f : 0.0f);
    self.click_count.hidden = !hidden;
    self.buttons_constraint.constant = (hidden ? 0.0f : self.blur_view.bounds.size.width);
  }];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  if ([self.delegate userScrolling:self])
    return;
  [self setButtonsHidden:NO animateWithDuration:0.2f];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  [self.delegate linkCellLostMouseHover:self];
  [self setButtonsHidden:YES animateWithDuration:0.2f];
}

- (void)hideControls
{
  [self setButtonsHidden:YES animateWithDuration:kMinimumTimeInterval];
}

- (void)checkMouseInside
{
  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
}

#pragma mark - Drawing

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

#pragma mark - Init

- (void)awakeFromNib
{
  dispatch_once(&_awake_token, ^
  {
    if (!_icon_admin)
      _icon_admin = [IAFunctions imageNamed:@"icon-admin-link"];
    if (!_icon_admin_hover)
      _icon_admin_hover = [IAFunctions imageNamed:@"icon-admin-link-hover"];
    if (!_icon_cancel)
      _icon_cancel = [IAFunctions imageNamed:@"link-icon-cancel"];
    if (!_icon_cancel_hover)
      _icon_cancel_hover = [IAFunctions imageNamed:@"link-icon-cancel-hover"];
    if (!_icon_clipboard)
      _icon_clipboard = [IAFunctions imageNamed:@"icon-clipboard"];
    if (!_icon_clipboard_hover)
      _icon_clipboard_hover = [IAFunctions imageNamed:@"icon-clipboard-hover"];
    if (!_icon_delete)
      _icon_delete = [IAFunctions imageNamed:@"icon-delete"];
    if (!_icon_delete_confirm)
      _icon_delete_confirm = [IAFunctions imageNamed:@"icon-delete-confirm"];
    if (!_icon_delete_hover)
      _icon_delete_hover = [IAFunctions imageNamed:@"icon-delete-hover"];

    self.cancel.normal_image = _icon_cancel;
    self.cancel.hover_image = _icon_cancel_hover;
    self.cancel.toolTip = NSLocalizedString(@"Cancel", nil);

    self.link.normal_image = _icon_admin;
    self.link.hover_image = _icon_admin_hover;
    self.link.toolTip = NSLocalizedString(@"Administrate link", nil);

    self.clipboard.normal_image = _icon_clipboard;
    self.clipboard.hover_image = _icon_clipboard_hover;
    self.clipboard.toolTip = NSLocalizedString(@"Copy link", nil);

    self.delete_link.normal_image = _icon_delete;
    self.delete_link.hover_image = _icon_delete_hover;
    self.delete_link.toolTip = NSLocalizedString(@"Delete link", nil);
  });
}

- (void)prepareForReuse
{
  _delegate = nil;
  _click_count = 0;
  self.buttons_constraint.constant = 0.0f;
  self.click_count.hidden = NO;
  self.click_count.alphaValue = 1.0f;
  self.delete_link.normal_image = _icon_delete;
  self.delete_link.hover_image = _icon_delete_hover;
}

- (void)setupCellWithLink:(InfinitLinkTransaction*)link
              andDelegate:(id<InfinitLinkCellProtocol>)delegate
         withOnlineStatus:(BOOL)status
{
  _delegate = delegate;
  _transaction = link;
  self.click_count.count = link.click_count;
  self.icon_view.icon = [InfinitLinkIconManager iconForFilename:link.name];
  self.name.stringValue = link.name;
  if (self.transaction.status == gap_transaction_transferring)
  {
    self.progress_indicator.hidden = NO;
    [self setProgress:self.transaction.progress withAnimation:NO andOnline:status];
  }
  else if (self.transaction.status == gap_transaction_on_other_device)
  {
    self.information.stringValue = NSLocalizedString(@"Uploading elsewhere", nil);
  }
  else
  {
    self.progress_indicator.hidden = YES;
    NSString* time_str = [InfinitTime relativeDateOf:self.transaction.mtime longerFormat:YES];
    NSString* data_str = [InfinitDataSize fileSizeStringFrom:link.size];
    self.information.stringValue = [NSString stringWithFormat:@"%@ – %@", data_str, time_str];
  }
  self.cancel.hidden = !(self.transaction.status == gap_transaction_transferring ||
                         self.transaction.status == gap_transaction_on_other_device);
}

#pragma mark - Progress Handling

- (void)setProgress:(CGFloat)progress
{
  [self setProgress:progress withAnimation:YES andOnline:YES];
}

- (void)setProgress:(CGFloat)progress
      withAnimation:(BOOL)animate
          andOnline:(BOOL)status
{
  NSString* upload_str;
  if (status)
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
      context.duration = 1.0f;
      [self.progress_indicator.animator setDoubleValue:progress];
    } completionHandler:^
    {
      self.progress_indicator.doubleValue = progress;
    }];
  }
  else
  {
    self.progress_indicator.doubleValue = progress;
  }
}

#pragma mark - Button Handling

- (IBAction)cancelClicked:(NSButton*)sender
{
  [self.delegate linkCell:self gotCancelForLink:self.transaction];
}

- (IBAction)administerLinkClicked:(NSButton*)sender
{
  InfinitStateManager* manager = [InfinitStateManager sharedInstance];
  [manager webLoginTokenWithCompletionBlock:^(InfinitStateResult* result,
                                              NSString* token,
                                              NSString* email)
  {
    if (!result.success || !token.length || !email.length)
      return;
    NSString* link_str =
      [NSString stringWithFormat:@"%@?login_token=%@&email=%@", self.transaction.link, token, email];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:link_str]];
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_OPEN_LINK];
  }];
}

- (IBAction)clipboardClicked:(NSButton*)sender
{
  NSPasteboard* paste_board = [NSPasteboard generalPasteboard];
  [paste_board declareTypes:@[NSStringPboardType] owner:nil];
  [paste_board setString:self.transaction.link forType:NSStringPboardType];
  [self.delegate linkCell:self gotCopyToClipboardForLink:self.transaction];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_COPY_LINK];
}

- (IBAction)deleteLinkClicked:(NSButton*)sender
{
  _delete_clicks++;
  if (self.delete_clicks < 2)
  {
    self.delete_link.normal_image = _icon_delete_confirm;
    self.delete_link.hover_image = _icon_delete_confirm;
    self.delete_link.image = _icon_delete_confirm;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
    {
      [self.link.animator setAlphaValue:0.0f];
      [self.clipboard.animator setAlphaValue:0.0f];
    } completionHandler:nil];
  }
  [self.delegate linkCell:self gotDeleteForLink:self.transaction];
}

@end
