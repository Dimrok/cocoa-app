//
//  IAFunctions.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
// Library of functions which are used throughout the application. These include generating human
// friendly times, making round avatars, etc.

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface IAFunctions : NSObject

+ (NSBezierPath*)roundedBottomBezierWithRect:(NSRect)rect
                                cornerRadius:(CGFloat)corner_radius;

+ (NSBezierPath*)roundedTopBezierWithRect:(NSRect)rect
                             cornerRadius:(CGFloat)corner_radius;

+ (NSBezierPath*)roundedLeftSideBezierWithRect:(NSRect)rect
                                  cornerRadius:(CGFloat)corner_radius;

+ (NSImage*)imageNamed:(NSString*)imageName;

+ (NSDictionary*)textStyleWithFont:(NSFont*)font
                    paragraphStyle:(NSParagraphStyle*)paragraph_style
                            colour:(NSColor*)colour
                            shadow:(NSShadow*)shadow;

+ (NSShadow*)shadowWithOffset:(NSSize)offset
                   blurRadius:(CGFloat)blur_radius
                       colour:(NSColor*)colour;

+ (NSImage*)makeRoundAvatar:(NSImage*)square_image
                 ofDiameter:(CGFloat)diameter
      withBorderOfThickness:(CGFloat)border_thickness
                   inColour:(NSColor*)colour
          andShadowOfRadius:(CGFloat)shadow_radius;

+ (NSString*)numberInUnits:(NSNumber*)num;

+ (NSImage*)addressBookUserAvatar;

+ (NSImage*)makeAvatarFor:(NSString*)fullname;

+ (NSString*)osVersionString;

@end
