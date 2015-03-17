//
//  IAFunctions.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAFunctions.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.Functions");

@implementation IAFunctions

+ (NSBezierPath*)roundedBottomBezierWithRect:(NSRect)rect
                                cornerRadius:(CGFloat)corner_radius
{
  NSBezierPath* res = [NSBezierPath bezierPath];
  CGFloat x = rect.origin.x;
  CGFloat y = rect.origin.y;
  CGFloat width = NSWidth(rect);
  CGFloat height = NSHeight(rect);
  [res moveToPoint:NSMakePoint(x, y + height)];
  [res appendBezierPathWithArcWithCenter:NSMakePoint(x + corner_radius, y + corner_radius)
                                  radius:corner_radius
                              startAngle:180.0
                                endAngle:270.0];
  [res appendBezierPathWithArcWithCenter:NSMakePoint(x + width - corner_radius, y + corner_radius)
                                  radius:corner_radius
                              startAngle:270.0
                                endAngle:0.0];
  [res lineToPoint:NSMakePoint(x + width, y + height)];
  [res lineToPoint:NSMakePoint(x, y + height)];
  [res closePath];
  return res;
}

+ (NSBezierPath*)roundedTopBezierWithRect:(NSRect)rect
                             cornerRadius:(CGFloat)corner_radius
{
  NSBezierPath* res = [NSBezierPath bezierPath];
  CGFloat x = rect.origin.x;
  CGFloat y = rect.origin.y;
  CGFloat width = NSWidth(rect);
  CGFloat height = NSHeight(rect);
  [res moveToPoint:NSMakePoint(x, y)];
  [res lineToPoint:NSMakePoint(x + width, y)];
  [res appendBezierPathWithArcWithCenter:NSMakePoint(x + width - corner_radius,
                                                     y + height - corner_radius)
                                  radius:corner_radius
                              startAngle:0.0
                                endAngle:90.0];
  [res lineToPoint:NSMakePoint(x + corner_radius, y + height)];
  [res appendBezierPathWithArcWithCenter:NSMakePoint(x + corner_radius, y + height - corner_radius)
                                  radius:corner_radius
                              startAngle:90.0
                                endAngle:180.0];
  [res lineToPoint:NSMakePoint(x, y)];
  return res;
}

+ (NSBezierPath*)roundedLeftSideBezierWithRect:(NSRect)rect
                                  cornerRadius:(CGFloat)corner_radius
{
  NSBezierPath* res = [NSBezierPath bezierPath];
  CGFloat x = rect.origin.x;
  CGFloat y = rect.origin.y;
  CGFloat width = NSWidth(rect);
  CGFloat height = NSHeight(rect);
  [res moveToPoint:NSMakePoint(x + corner_radius, y)];
  [res lineToPoint:NSMakePoint(x + width, y)];
  [res lineToPoint:NSMakePoint(x + width, y + height)];
  [res lineToPoint:NSMakePoint(x + corner_radius, y + height)];
  [res appendBezierPathWithArcWithCenter:NSMakePoint(x + corner_radius, y + height - corner_radius)
                                  radius:corner_radius
                              startAngle:90.0
                                endAngle:180.0];
  [res lineToPoint:NSMakePoint(x, y + corner_radius)];
  [res appendBezierPathWithArcWithCenter:NSMakePoint(x + corner_radius, y + corner_radius)
                                  radius:corner_radius
                              startAngle:180.0
                                endAngle:270.0];
  return res;
}

+ (NSBundle*)bundle
{
	static NSBundle* bundle=nil;
	if (bundle == nil)
		bundle = [NSBundle bundleForClass:self.class];
	return bundle;
}

+ (NSImage*)imageNamed:(NSString*)imageName
{
  if (imageName == nil)
  {
    NSLog(@"WARNING: Retrieve image with nil name");
    return nil;
  }
	NSString* path = [self.bundle pathForImageResource:imageName];
  if (path == nil)
  {
    NSLog(@"WARNING: Cannot find path for image %@", imageName);
    return nil;
  }
  NSImage* img = [[NSImage alloc] initWithContentsOfFile:path];
  if (img == nil)
  {
    NSLog(@"WARNING: Cannnot load image from path %@", path);
    return nil;
  }
  return img;
}

+ (NSDictionary*)textStyleWithFont:(NSFont*)font
                    paragraphStyle:(NSParagraphStyle*)paragraph_style
                            colour:(NSColor*)colour
                            shadow:(NSShadow*)shadow
{
  NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
  if (font != nil)
    [dict setObject:font forKey:NSFontAttributeName];
  if (paragraph_style != nil)
    [dict setObject:paragraph_style forKey:NSParagraphStyleAttributeName];
  if (colour != nil)
    [dict setObject:colour forKey:NSForegroundColorAttributeName];
  if (shadow != nil)
    [dict setObject:shadow forKey:NSShadowAttributeName];
  return [NSDictionary dictionaryWithDictionary:dict];
}

+ (NSShadow*)shadowWithOffset:(NSSize)offset
                   blurRadius:(CGFloat)blur_radius
                       colour:(NSColor*)colour
{
  NSShadow* shadow = [[NSShadow alloc] init];
  shadow.shadowOffset = offset;
  shadow.shadowBlurRadius = blur_radius;
  shadow.shadowColor = colour;
  return shadow;
}

+ (NSImage*)makeRoundAvatar:(NSImage*)square_image
                 ofDiameter:(CGFloat)diameter
      withBorderOfThickness:(CGFloat)border_thickness
                   inColour:(NSColor*)colour
          andShadowOfRadius:(CGFloat)shadow_radius
{
  CGFloat image_diameter = diameter;
  image_diameter -= 2.0 * border_thickness;
  image_diameter -= 2.0 * shadow_radius;

  square_image.size = NSMakeSize(image_diameter, image_diameter);

  NSImage* res = [[NSImage alloc] initWithSize:NSMakeSize(diameter, diameter)];
  [res lockFocus];

  [NSGraphicsContext saveGraphicsState];

  NSShadow* shadow = [[NSShadow alloc] init];
  if (shadow_radius > 0.0)
  {
    shadow.shadowBlurRadius = shadow_radius;
    shadow.shadowColor = IA_GREY_COLOUR(0);
    shadow.shadowOffset = NSZeroSize;
    [shadow set];
  }

  if (border_thickness > 0.0)
  {
    NSBezierPath* border = [NSBezierPath bezierPathWithOvalInRect:
                            NSMakeRect(shadow_radius,
                                       shadow_radius,
                                       diameter - (2.0 * shadow_radius),
                                       diameter - (2.0 * shadow_radius))];
    [colour set];
    [border fill];
  }

  [NSGraphicsContext restoreGraphicsState];

  [NSGraphicsContext saveGraphicsState];

  [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

  NSBezierPath* image_path = [NSBezierPath bezierPathWithOvalInRect:
                              NSMakeRect(border_thickness + shadow_radius,
                                         border_thickness + shadow_radius,
                                         image_diameter,
                                         image_diameter)];
  [image_path addClip];
  [square_image drawInRect:NSMakeRect(border_thickness + shadow_radius,
                                      border_thickness + shadow_radius,
                                      image_diameter,
                                      image_diameter)
                  fromRect:NSZeroRect
                 operation:NSCompositeSourceOver
                  fraction:1.0];

  [res unlockFocus];

  [NSGraphicsContext restoreGraphicsState];
  return res;
}

+ (NSString*)numberInUnits:(NSNumber*)num
{
  NSString* res;
  CGFloat real_num = num.doubleValue;

  if (real_num < pow(10.0, 3.0))
    res = [NSString stringWithFormat:@"%.0f", real_num];
  else if (real_num < pow(10.0, 6.0))
    res = [NSString stringWithFormat:@"%.1f K", real_num / pow(10.0, 3.0)];
  else if (real_num < pow(10.0, 9.0))
    res = [NSString stringWithFormat:@"%.2f M", real_num / pow(10.0, 6.0)];
  else
    res = [NSString stringWithFormat:@"%.3f G", real_num / pow(10.0, 9.0)];

  return res;
}

+ (NSImage*)makeAvatarFor:(NSString*)fullname
{
  NSImage* avatar = [[NSImage alloc] initWithSize:NSMakeSize(256.0, 256.0)];

  NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                            traits:NSUnboldFontMask
                                                            weight:5
                                                              size:105.0];
  NSDictionary* style = [IAFunctions textStyleWithFont:font
                                        paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                colour:IA_GREY_COLOUR(255.0)
                                                shadow:nil];
  NSArray* chunks;
  if (fullname.length > 0)
    chunks = [fullname componentsSeparatedByString:@" "];
  else // for case when fullname has no length, add a U for unknown
    chunks = [NSArray arrayWithObject:@"U"];
  NSMutableString* letters_str = [NSMutableString string];
  NSRange char_range;
  for (NSString* chunk in chunks)
  {
    if (chunk.length > 0)
    {
      char_range = [chunk rangeOfComposedCharacterSequenceAtIndex:0];
      [letters_str appendString:[NSString stringWithFormat:@"%@", [chunk substringWithRange:char_range]]];
    }
  }

  NSAttributedString* letters = [[NSAttributedString alloc]
                                 initWithString:[letters_str uppercaseString]
                                 attributes:style];
  NSRect letter_rect = NSMakeRect((avatar.size.width - letters.size.width) / 2.0,
                                  (avatar.size.height - letters.size.height) / 2.0,
                                  letters.size.width,
                                  letters.size.height);

  NSBezierPath* bg = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0,
                                                                 0.0,
                                                                 avatar.size.width,
                                                                 avatar.size.height)];
  [avatar lockFocus];
  [IA_RGB_COLOUR(202.0, 217.0, 223.0) set];
  [bg fill];
  [letters drawInRect:letter_rect];
  [avatar unlockFocus];

  return avatar;
}

+ (NSImage*)addressBookUserAvatar
{
	ABAddressBook* address_book = [ABAddressBook sharedAddressBook];
  if (address_book == nil)
  {
    ELLE_LOG("Infinit doesn't have access to Address Book");
    return nil;
  }

	NSData* image_data = nil;

  if (address_book != nil)
    image_data = address_book.me.imageData;

	NSImage* result;
  if (image_data == nil)
    result = nil;
  else
    result = [[NSImage alloc] initWithData:image_data];

	return result;
}

+ (NSString*)osVersionString
{
  NSNumber* major_version = [IAFunctions osMajorVersion];
  NSNumber* minor_version = [IAFunctions osMinorVersion];
  NSNumber* bugfix_version = [IAFunctions osBugfixVersion];
  if (major_version.integerValue == -1 ||
      minor_version.integerValue == -1 ||
      bugfix_version.integerValue == -1)
  {
    return @"Unknown";
  }
  else
  {
    return [NSString stringWithFormat:@"%@.%@.%@", major_version,
            minor_version,
            bugfix_version];
  }
}

+ (NSNumber*)osMajorVersion
{
  SInt32 major_version;
  if (Gestalt(gestaltSystemVersionMajor, &major_version) == noErr)
    return [NSNumber numberWithInt:major_version];
  else
    return nil;
}

+ (NSNumber*)osMinorVersion
{
  SInt32 minor_version;
  if (Gestalt(gestaltSystemVersionMinor, &minor_version) == noErr)
    return [NSNumber numberWithInt:minor_version];
  else
    return nil;
}

+ (NSNumber*)osBugfixVersion
{
  SInt32 bugfix_version;
  if (Gestalt(gestaltSystemVersionBugFix, &bugfix_version) == noErr)
    return [NSNumber numberWithInt:bugfix_version];
  else
    return nil;
}

+ (INFINIT_OS_X_VERSION)osxVersion
{
  NSInteger major_version = [[IAFunctions osMajorVersion] integerValue];
  NSInteger minor_version = [[IAFunctions osMinorVersion] integerValue];
  if (major_version != 10)
    return INFINIT_OS_X_VERSION_UNKNOWN;
  switch (minor_version)
  {
    case 7:
      return INFINIT_OS_X_VERSION_10_7;
    case 8:
      return INFINIT_OS_X_VERSION_10_8;
    case 9:
      return INFINIT_OS_X_VERSION_10_9;
    case 10:
      return INFINIT_OS_X_VERSION_10_10;

    default:
      return INFINIT_OS_X_VERSION_UNKNOWN;
  }
}

@end
