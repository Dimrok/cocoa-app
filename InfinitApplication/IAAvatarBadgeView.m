//
//  IAAvatarBadgeView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/21/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAAvatarBadgeView.h"

#import <QuartzCore/QuartzCore.h>

@implementation IAAvatarBadgeView
{
    NSUInteger _count;
    NSImage* _badge;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        _badge = [IAFunctions imageNamed:@"badge"];
    }
    return self;
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (_count > 0)
    {
        [_badge drawInRect:self.bounds
                  fromRect:NSZeroRect
                 operation:NSCompositeSourceOver
                  fraction:1.0];
        NSDictionary* num_attrs = [IAFunctions
                                   textStyleWithFont:[NSFont boldSystemFontOfSize:11.0]
                                      paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                              colour:IA_GREY_COLOUR(255.0)
                                              shadow:nil];
        NSAttributedString* num_str;
        if (_count < 10)
        {
            num_str = [[NSAttributedString alloc]
                       initWithString:[[NSNumber numberWithUnsignedInteger:_count] stringValue]
                                                      attributes:num_attrs];
        }
        else
        {
            num_str = [[NSAttributedString alloc] initWithString:@"+"
                                                      attributes:num_attrs];
        }
        [num_str drawAtPoint:NSMakePoint((NSWidth(self.bounds) - num_str.size.width) / 2.0,
                                         (NSHeight(self.bounds) - num_str.size.height) / 2.0
                                            + 2.0)];
    }
}

//- General Functions ------------------------------------------------------------------------------

- (void)setBadgeCount:(NSUInteger)count
{
    if (_count == count)
        return;
    else
        _count = count;
    
    [self setNeedsDisplay:YES];
}

//- Animation --------------------------------------------------------------------------------------

+ (id)defaultAnimationForKey:(NSString*)key
{
    if ([key isEqualToString:@"totalProgress"])
        return [CABasicAnimation animation];
    
    return [super defaultAnimationForKey:key];
}

@end
