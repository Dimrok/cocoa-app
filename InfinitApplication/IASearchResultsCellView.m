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
    }
    
    return self;
}

- (NSString*)description
{
    return @"[SearchResultCell]";
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
