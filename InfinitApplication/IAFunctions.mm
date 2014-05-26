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

+ (BOOL)stringIsValidEmail:(NSString*)str
{
  NSString* email_regex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
  NSPredicate* email_test = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", email_regex];
  return [email_test evaluateWithObject:str];
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
    shadow.shadowColor = IA_RGBA_COLOUR(32.0, 32.0, 32.0, 0.2);
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

// Do not confuse MB and MiB. Apple use MB, GB, etc for their file and storage sizes.
+ (NSString*)fileSizeStringFrom:(NSNumber*)file_size
{
  NSString* res;
  CGFloat size = file_size.doubleValue;
  
  if (size < pow(10.0, 3.0))
    res = [NSString stringWithFormat:@"%.0f B", size];
  else if (size < pow(10.0, 6.0))
    res = [NSString stringWithFormat:@"%.0f KB", size / pow(10.0, 3.0)];
  else if (size < pow(10.0, 9.0))
    res = [NSString stringWithFormat:@"%.1f MB", size / pow(10.0, 6.0)];
  else if (size < pow(10.0, 12.0))
    res = [NSString stringWithFormat:@"%.2f GB", size / pow(10.0, 9.0)];
  else
    res = [NSString stringWithFormat:@"%.3f TB", size / pow(10.0, 12.0)];
  
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

+ (NSString*)timeRemainingFrom:(NSTimeInterval)seconds_left
{
  NSString* res;
  
  if (seconds_left < 10)
    res = NSLocalizedString(@"less than 10 s", @"less than 10 s");
  else if (seconds_left < 60)
    res = NSLocalizedString(@"less than 1 min", @"less than 1 min");
  else if (seconds_left < 90)
    res = NSLocalizedString(@"about 1 min", @"about 1 min");
  else if (seconds_left < 3600)
    res = [NSString stringWithFormat:@"%.0f min", seconds_left / 60];
  else if (seconds_left < 86400)
    res = [NSString stringWithFormat:@"%.0f h", seconds_left / 3600];
  else if (seconds_left < 172800)
  {
    double days = seconds_left / 86400;
    double hours = days - floor(days);
    days = floor(days);
    res = [NSString stringWithFormat:@"%.0f d %.1f h", days, hours];
  }
  else
  {
    res = NSLocalizedString(@"more than two days", @"more than two days");
  }
  
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
  for (NSString* chunk in chunks)
    if (chunk.length > 0)
      [letters_str appendString:[NSString stringWithFormat:@"%c", [chunk characterAtIndex:0]]];
  
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

+ (BOOL)isToday:(NSDate*)date
{
  NSDate* today = [NSDate date];
  NSInteger components = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
  NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents* today_components = [gregorian components:components
                                                    fromDate:today];
  NSDateComponents* date_components = [gregorian components:components
                                                   fromDate:date];
  if ([date_components isEqual:today_components])
    return YES;
  else
    return NO;
}

+ (BOOL)isInLastWeek:(NSDate*)date
{
  NSDate* now = [NSDate date];
  NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSInteger components = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
  NSDateComponents* today_components = [gregorian components:components
                                                    fromDate:now];
  NSDate* today = [gregorian dateFromComponents:today_components];
  NSDateComponents* minus_six_days = [[NSDateComponents alloc] init];
  minus_six_days.day = -6;
  NSDate* six_days_ago = [gregorian dateByAddingComponents:minus_six_days
                                                    toDate:today
                                                   options:0];
  if ([[date earlierDate:now] isEqualToDate:date] &&
      [[date laterDate:six_days_ago] isEqualToDate:date])
  {
    return YES;
  }
  return NO;
}

+ (NSString*)relativeDateOf:(NSTimeInterval)timestamp
               longerFormat:(BOOL)longer
{
  NSDate* transaction_date = [NSDate dateWithTimeIntervalSince1970:timestamp];
  NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  formatter.locale = [NSLocale currentLocale];
  NSString* res;
  if (timestamp <  now && timestamp > (now - 3 * 60.0)) // 3 min ago
  {
    res = NSLocalizedString(@"Now", @"Now");
  }
  else if (timestamp < now && timestamp > (now - 60 * 60.0)) // an hour ago
  {
    CGFloat time_ago = floor((now - timestamp) / 60.0);
    res = [NSString stringWithFormat:@"%.0f %@", time_ago, NSLocalizedString(@"min ago", nil)];
  }
  else if ([IAFunctions isToday:transaction_date])
  {
    formatter.timeStyle = NSDateFormatterShortStyle;
    res = [formatter stringFromDate:transaction_date];
  }
  else if ([IAFunctions isInLastWeek:transaction_date])
  {
    if (longer)
      formatter.dateFormat = @"EEEE";
    else
      formatter.dateFormat = @"EEE";
    res = [formatter stringFromDate:transaction_date];
  }
  else
  {
    if (longer)
      formatter.dateFormat = @"d MMMM";
    else
      formatter.dateFormat = @"d MMM";
    res = [formatter stringFromDate:transaction_date];
  }
  return res.capitalizedString;
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
      
    default:
      return INFINIT_OS_X_VERSION_UNKNOWN;
  }
}

+ (NSString*)printFrame:(NSRect)rect
{
  return [NSString stringWithFormat:@"frame: (%f, %f) (%f x %f)", rect.origin.x, rect.origin.y,
          rect.size.width, rect.size.height];
}

+ (NSString*)printPoint:(NSPoint)point
{
  return [NSString stringWithFormat:@"point: (%f, %f)", point.x, point.y];
}

@end
