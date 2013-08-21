//
//  IAAvatarBadgeView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/21/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAAvatarBadgeView.h"

@implementation IAAvatarBadgeView
{
    NSUInteger _count;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (_count > 0)
    {
        NSImage* badge = [IAFunctions imageNamed:@"badge"];
        [badge drawInRect:self.bounds
                 fromRect:NSZeroRect
                operation:NSCompositeSourceOver
                 fraction:1.0];
        NSDictionary* num_attrs = [IAFunctions
                                   textStyleWithFont:[NSFont boldSystemFontOfSize:12.0]
                                      paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                              colour:IA_GREY_COLOUR(255.0)
                                              shadow:nil];
        NSAttributedString* num_str;
        if (_count < 10)
        {
            num_str = [[NSAttributedString alloc]
                       initWithString:[NSNumber numberWithUnsignedInteger:_count].stringValue
                                                      attributes:num_attrs];
        }
        else
        {
            num_str = [[NSAttributedString alloc] initWithString:@"+"
                                                      attributes:num_attrs];
        }
        [num_str drawAtPoint:NSMakePoint((self.bounds.size.width - num_str.size.width) / 2.0,
                                         (self.bounds.size.height - num_str.size.height) / 2.0
                                            + 3.0)];
    }
}


- (void)setBadgeCount:(NSUInteger)count
{
    if (_count == count)
        return;
    else
        _count = count;
    
    [self setNeedsDisplay:YES];
}

@end
