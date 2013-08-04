//
//  IASimpleSendViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASimpleSendViewController.h"

@interface IASimpleSendViewController ()

@end

@interface IASimpleSendFooterView : NSView
@end

@implementation IASimpleSendFooterView

- (void)drawRect:(NSRect)dirtyRect
{
    // Dark line
    NSRect dark_line_rect = NSMakeRect(self.bounds.origin.x,
                                       self.bounds.origin.y + self.bounds.size.height - 1.0,
                                       self.bounds.size.width,
                                       1.0);
    NSBezierPath* dark_path = [NSBezierPath bezierPathWithRect:dark_line_rect];
    [TH_RGBCOLOR(223.0, 223.0, 223.0) set];
    [dark_path fill];
    
    // White line
    NSRect white_line_rect = NSMakeRect(self.bounds.origin.x,
                                        self.bounds.origin.y + self.bounds.size.height - 2.0,
                                        self.bounds.size.width,
                                        1.0);
    NSBezierPath* white_path = [NSBezierPath bezierPathWithRect:white_line_rect];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_path fill];
    
    // Grey background with rounded corners
    NSRect grey_rect = NSMakeRect(self.bounds.origin.x,
                                  self.bounds.origin.y,
                                  self.bounds.size.width,
                                  self.bounds.size.height - 2.0);
    NSBezierPath* grey_path = [IAFunctions roundedBottomBezierWithRect:grey_rect cornerRadius:5.0];
    [TH_RGBCOLOR(242.0, 242.0, 242.0) set];
    [grey_path fill];
}

@end

@implementation IASimpleSendViewController
{
@private
    id<IASimpleSendViewProtocol> _delegate;
    
    IAUserSearchViewController* _user_search_controller;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IASimpleSendViewProtocol>)delegate
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _user_search_controller = [[IAUserSearchViewController alloc] initWithDelegate:self];
    }
    return self;
}

- (void)awakeFromNib
{
    self.main_view.autoresizingMask = NSViewHeightSizable;
    [self.view replaceSubview:self.main_view with:_user_search_controller.view];
    [_user_search_controller.view setFrameOrigin:self.main_view.frame.origin];
    [_user_search_controller.view setFrameSize:self.main_view.frame.size];
    self.main_view = _user_search_controller.view;
}


- (NSString*)description
{
    return @"[SimpleSendView]";
}

//- General Functions ------------------------------------------------------------------------------


@end
