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
	static NSBundle *bundle=nil;
	if (bundle==nil)
		bundle=[NSBundle bundleForClass:[self class]];
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

@end
