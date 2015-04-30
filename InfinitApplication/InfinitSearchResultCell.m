//
//  InfinitSearchResultCell.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitSearchResultCell.h"

#import <Gap/InfinitColor.h>
#import <Gap/NSString+email.h>

@interface InfinitSearchResultCell ()

@property (nonatomic, weak) IBOutlet NSImageView* result_avatar;
@property (nonatomic, weak) IBOutlet NSTextField* result_fullname;
@property (nonatomic, weak) IBOutlet NSImageView* result_type;

@end

@implementation InfinitSearchResultCell
{
  NSTrackingArea* _tracking_area;
}

static NSDictionary* _fullname_style = nil;
static NSDictionary* _email_style = nil;

- (void)prepareForReuse
{
  [self removeTrackingArea:_tracking_area];
  _hover = NO;
  _line = NO;
  [super prepareForReuse];
  self.result_type.image = nil;
}

- (void)dealloc
{
  _tracking_area = nil;
}

- (void)setModel:(InfinitSearchRowModel*)model
{
  _model = model;
  if (_fullname_style == nil)
  {
    NSFont* name_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                   traits:NSUnboldFontMask
                                                                   weight:3
                                                                     size:12.0];
    _fullname_style = [IAFunctions textStyleWithFont:name_font
                                      paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                              colour:IA_RGB_COLOUR(37, 47, 51)
                                              shadow:nil];
    NSFont* email_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                    traits:NSUnboldFontMask
                                                                    weight:3
                                                                      size:11.0];
    _email_style = [IAFunctions textStyleWithFont:email_font
                                   paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                           colour:IA_GREY_COLOUR(160)
                                           shadow:nil];
  }
  NSMutableAttributedString* fullname_norm_str =
    [[NSMutableAttributedString alloc] initWithString:self.model.fullname
                                           attributes:_fullname_style];
  if ([self.model.destination isKindOfClass:NSString.class] && [self.model.destination infinit_isEmail] > 0)
  {
    NSAttributedString* email_str =
      [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  (%@)", self.model.destination]
                                      attributes:_email_style];
    [fullname_norm_str appendAttributedString:email_str];
  }
  else if ([self.model.destination isKindOfClass:InfinitUser.class])
  {
    InfinitUser* user = self.model.destination;
    if (user.favorite || user.is_self)
      self.result_type.image = [NSImage imageNamed:@"send-icon-favorite"];

    if (user.is_self)
    {
      fullname_norm_str =
        [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Me (my other devices)", nil)
                                               attributes:_fullname_style];
    }
  }
  else if ([self.model.destination isKindOfClass:InfinitDevice.class])
  {
    InfinitDevice* device = self.model.destination;
    switch (device.type)
    {
      case InfinitDeviceTypeAndroid:
        self.result_type.image = [NSImage imageNamed:@"send-icon-device-android"];
        break;
      case InfinitDeviceTypeiPhone:
        self.result_type.image = [NSImage imageNamed:@"send-icon-device-ios"];
        break;
      case InfinitDeviceTypeMacLaptop:
        self.result_type.image = [NSImage imageNamed:@"send-icon-device-mac"];
        break;

      default:
        self.result_type.image = [NSImage imageNamed:@"send-icon-device-windows"];
        break;
    }
  }
  self.result_avatar.image = [IAFunctions makeRoundAvatar:self.model.avatar
                                               ofDiameter:24.0
                                    withBorderOfThickness:0.0
                                                 inColour:IA_GREY_COLOUR(255.0)
                                        andShadowOfRadius:0.0];
  self.result_fullname.attributedStringValue = fullname_norm_str;
}

#pragma mark - Mouse Handling

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
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  if (!CGCursorIsVisible())
    return;
  _hover = YES;
  [self setExternalHover:YES];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  if (!CGCursorIsVisible())
    return;
  _hover = NO;
  [self setExternalHover:NO];
}

- (void)mouseDown:(NSEvent*)theEvent
{
  if (theEvent.clickCount == 1)
    [_delegate searchResultCellGotSelected:self];
}

- (void)setExternalHover:(BOOL)hover
{
  [self setHover:hover];
  [_delegate searchResultCell:self gotHover:hover];
}

- (void)setHover:(BOOL)hover
{
  _hover = hover;
  [self setNeedsDisplay:YES];
}  


#pragma mark - Drawing

- (BOOL)isOpaque
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [[NSColor whiteColor] set];
  NSRectFill(self.bounds);

  if (self.line)
  {
    NSRect dark_rect = NSMakeRect(50.0f, 0.0f, self.bounds.size.width - 70.0f, 1.0f);
    [[InfinitColor colorWithGray:244] set];
    NSRectFill(dark_rect);
  }

  if (self.hover)
  {
    NSRect hover = NSMakeRect(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.height);
    [[InfinitColor colorWithRed:240 green:252 blue:251] set];
    NSRectFill(hover);
  }
}


@end
