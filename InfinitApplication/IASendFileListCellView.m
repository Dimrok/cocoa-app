//
//  IASendFileListCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/5/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASendFileListCellView.h"

@implementation IASendFileListCellView

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        // Initialization code here.
    }
    
    return self;
}

- (NSString*)description
{
    return @"[SendFileListCellView]";
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Grey backgrounds
    NSRect grey_rect = NSMakeRect(self.bounds.origin.x,
                                  self.bounds.origin.y + 2.0,
                                  self.bounds.size.width,
                                  self.bounds.size.height - 2.0);
    NSBezierPath* grey_path = [NSBezierPath bezierPathWithRect:grey_rect];
    [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
    [grey_path fill];
    
    // White line
    NSRect white_rect = NSMakeRect(self.bounds.origin.x,
                                   self.bounds.origin.y + 1.0,
                                   self.bounds.size.width,
                                   1.0);
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_rect];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_line fill];
    
    // Dark grey line
    NSRect dark_grey_rect = NSMakeRect(self.bounds.origin.x,
                                       self.bounds.origin.y,
                                       self.bounds.size.width,
                                       1.0);
    NSBezierPath* dark_grey_line = [NSBezierPath bezierPathWithRect:dark_grey_rect];
    [TH_RGBCOLOR(220.0, 220.0, 220.0) set];
    [dark_grey_line fill];
}

@end
