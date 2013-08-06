//
//  IASearchResultsCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASearchResultsCellView.h"

@implementation IASearchResultsCellView
{
    BOOL _is_favourite;
}

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
    return @"[SearchResultCell]";
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
    
    // Background
    NSRect bg_rect = NSMakeRect(self.bounds.origin.x,
                                self.bounds.origin.y,
                                self.bounds.size.width,
                                self.bounds.size.height - 2.0);
    NSBezierPath* bg_path = [NSBezierPath bezierPathWithRect:bg_rect];
    [TH_RGBCOLOR(247.0, 247.0, 247.0) set];
    [bg_path fill];
}

//- Set Cell Values --------------------------------------------------------------------------------

- (void)setUserFullname:(NSString*)fullname
{
    NSDictionary* style = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                          paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                  colour:TH_RGBCOLOR(37.0, 47.0, 51.0)
                                                  shadow:nil];
    NSAttributedString* fullname_str = [[NSAttributedString alloc] initWithString:fullname
                                                                       attributes:style];
    self.result_fullname.attributedStringValue = fullname_str;
}

- (void)setUserAvatar:(NSImage*)image
{
    self.result_avatar.image = image;
}

- (void)setUserFavourite:(BOOL)favourite
{
    _is_favourite = favourite;
    if (favourite)
        self.result_star.image = [IAFunctions imageNamed:@"icon-star-selected"];
    else
        self.result_star.image = [IAFunctions imageNamed:@"icon-star"];
}

//- Cell Actions -----------------------------------------------------------------------------------

- (IBAction)starClicked:(NSButton*)sender
{
    if (sender != self.result_star)
        return;
    // XXX make user a favourite
    if (_is_favourite)
    {
        _is_favourite = NO;
        self.result_star.image = [IAFunctions imageNamed:@"icon-star"];
    }
    else
    {
        _is_favourite = YES;
        self.result_star.image = [IAFunctions imageNamed:@"icon-star-selected"];
    }
}

@end
