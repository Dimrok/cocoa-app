//
//  IAFunctions.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAFunctions.h"

@implementation IAFunctions

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

@end
