//
//  IAFunctions.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAFunctions.h"

@implementation IAFunctions

+ (NSBezierPath*)roundedBottomBezierWithRect:(NSRect)rect
                                cornerRadius:(CGFloat)corner_radius
{
    NSBezierPath* res = [NSBezierPath bezierPath];
    CGFloat x = rect.origin.x;
    CGFloat y = rect.origin.y;
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
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

+ (NSBundle*)bundle
{
	static NSBundle* bundle=nil;
	if (bundle == nil)
		bundle = [NSBundle bundleForClass:[self class]];
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
    BOOL stricter_filter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString* stricter_filter_str = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString* lax_string = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString* email_regex = stricter_filter ? stricter_filter_str : lax_string;
    NSPredicate* email_test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", email_regex];
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
                        color:(NSColor*)colour
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
        shadow.shadowColor = TH_RGBACOLOR(0.0, 0.0, 0.0, 0.36);
        shadow.shadowOffset = NSZeroSize;
        [shadow set];
    }
    
    if (border_thickness > 0.0)
    {
        NSBezierPath* grey_border = [NSBezierPath bezierPathWithOvalInRect:
                                     NSMakeRect(shadow_radius,
                                                shadow_radius,
                                                diameter - (2.0 * shadow_radius),
                                                diameter - (2.0 * shadow_radius))];
        [TH_RGBCOLOR(239.0, 239.0, 239.0) set];
        [grey_border stroke];
        
        NSBezierPath* white_border = [NSBezierPath bezierPathWithOvalInRect:
                                      NSMakeRect(shadow_radius + 1.0,
                                                 shadow_radius + 1.0,
                                                 diameter - (2.0 * shadow_radius) - 2.0,
                                                 diameter - (2.0 * shadow_radius) - 2.0)];
        [white_border setLineWidth:(border_thickness)];
        [colour set];
        [white_border stroke];
    }
    
    [NSGraphicsContext restoreGraphicsState];

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
    return res;
}

+ (NSString*)fileSizeStringFrom:(NSUInteger)file_size
{
    NSString* res;
    CGFloat size = file_size;
    
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

+ (NSImage*)defaultAvatar
{
	return [IAFunctions imageNamed:@"avatar_default"];
}

+ (NSImage*)addressBookUserAvatar
{
	ABAddressBook* address_book = [ABAddressBook sharedAddressBook];
	NSData* image_data = address_book.me.imageData;
	NSImage* result;
    if (image_data == nil)
        result = [self defaultAvatar];
    else
        result = [[NSImage alloc] initWithData:image_data];
	return result;
}

@end
