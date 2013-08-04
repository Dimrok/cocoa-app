//
//  IASearchResultsCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASearchResultsCellView.h"

@implementation IASearchResultsCellView

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Dark line
    NSRect dark_rect = NSMakeRect(self.bounds.origin.x,
                                  self.bounds.origin.y + self.bounds.size.height - 1.0,
                                  self.bounds.size.width,
                                  1.0);
    NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:dark_rect];
    [TH_RGBCOLOR(209.0, 209.0, 209.0) set];
    [dark_line fill];

    // White line
    NSRect white_rect = NSMakeRect(self.bounds.origin.x,
                                   self.bounds.origin.y + self.bounds.size.height - 2.0,
                                   self.bounds.size.width,
                                   1.0);
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_rect];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_line fill];

    // Backgrounds
    NSRect bg_rect = NSMakeRect(self.bounds.origin.x,
                                 self.bounds.origin.y,
                                 self.bounds.size.width,
                                 self.bounds.size.height - 2.0);
    NSBezierPath* bg_path = [NSBezierPath bezierPathWithRect:bg_rect];
    [TH_RGBCOLOR(247.0, 247.0, 247.0) set];
    [bg_path fill];
}

@end
