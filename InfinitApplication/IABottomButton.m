//
//  IABottomButton.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IABottomButton.h"

@implementation IABottomButton

//- Initialisation ---------------------------------------------------------------------------------

@synthesize enabled = _enabled;
@synthesize hand_cursor = _hand_cursor;

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _enabled = NO;
        [self setIgnoresMultiClick:YES];
        _hand_cursor = YES;
    }
    return self;
}

//- Hand Cursor ------------------------------------------------------------------------------------

- (void)resetCursorRects
{
    if (!_hand_cursor)
    {
        [super resetCursorRects];
        return;
    }
    [super resetCursorRects];
    NSCursor* cursor = [NSCursor pointingHandCursor];
    [self addCursorRect:self.bounds cursor:cursor];
}

//- General Functions ------------------------------------------------------------------------------

- (BOOL)isEnabled
{
    return self.enabled;
}

- (void)setEnabled:(BOOL)flag
{    
    _enabled = flag;
    if (flag)
    {
        self.image = [IAFunctions imageNamed:@"bg-main-button"];
    }
    else
    {
        self.image = [IAFunctions imageNamed:@"bg-main-button-disabled"];
    }
}

- (void)mouseDown:(NSEvent*)theEvent
{
    if (!_enabled)
        return;
    [super mouseDown:theEvent];
}

@end
