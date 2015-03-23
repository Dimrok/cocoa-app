//
//  InfinitSearchEmailCell.m
//  InfinitApplication
//
//  Created by Christopher Crone on 23/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSearchEmailCell.h"

#import <Gap/InfinitColor.h>

@interface InfinitSearchEmailCell ()

@property (nonatomic, weak) IBOutlet NSImageView* avatar_view;
@property (nonatomic, weak) IBOutlet NSTextField* text_field;

@end

static NSImage* _email_avatar = nil;

@implementation InfinitSearchEmailCell

- (void)awakeFromNib
{
  if (_email_avatar == nil)
  {
    _email_avatar = [IAFunctions makeRoundAvatar:[NSImage imageNamed:@"send-icon-email-results"]
                                      ofDiameter:24.0f
                           withBorderOfThickness:0.0f 
                                        inColour:nil
                               andShadowOfRadius:0.0f];
  }
  self.avatar_view.image = _email_avatar;
}

- (void)setEmail:(NSString*)email
{
  NSString* text = [NSString stringWithFormat:NSLocalizedString(@"Send to \"%@\"", nil), email];
  self.text_field.stringValue = text;
}

- (BOOL)opaque
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [[InfinitColor colorWithRed:240 green:252 blue:251] set];
  NSRectFill(dirtyRect);
}

@end
