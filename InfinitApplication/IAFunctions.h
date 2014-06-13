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

typedef enum __INFINIT_OS_X_VERSION
{
  INFINIT_OS_X_VERSION_UNKNOWN = 0,
  INFINIT_OS_X_VERSION_10_7 = 1,
  INFINIT_OS_X_VERSION_10_8 = 2,
  INFINIT_OS_X_VERSION_10_9 = 3,
  INFINIT_OS_X_VERSION_10_10 = 4,
} INFINIT_OS_X_VERSION;

@interface IAFunctions : NSObject

+ (NSBezierPath*)roundedBottomBezierWithRect:(NSRect)rect
                                cornerRadius:(CGFloat)corner_radius;

+ (NSBezierPath*)roundedTopBezierWithRect:(NSRect)rect
                             cornerRadius:(CGFloat)corner_radius;

+ (NSBezierPath*)roundedLeftSideBezierWithRect:(NSRect)rect
                                  cornerRadius:(CGFloat)corner_radius;

+ (NSImage*)imageNamed:(NSString*)imageName;

+ (BOOL)stringIsValidEmail:(NSString*)str;

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

+ (NSString*)fileSizeStringFrom:(NSNumber*)file_size;

+ (NSString*)numberInUnits:(NSNumber*)num;

+ (NSString*)timeRemainingFrom:(NSTimeInterval)seconds_left;

+ (NSImage*)addressBookUserAvatar;

+ (NSString*)relativeDateOf:(NSTimeInterval)timestamp
               longerFormat:(BOOL)longer;

+ (NSImage*)makeAvatarFor:(NSString*)fullname;

+ (NSString*)osVersionString;

+ (INFINIT_OS_X_VERSION)osxVersion;

+ (NSString*)printFrame:(NSRect)rect;

+ (NSString*)printPoint:(NSPoint)point;

@end
