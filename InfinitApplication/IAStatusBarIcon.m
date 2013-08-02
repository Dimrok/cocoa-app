//
//  IAStatusBarIcon.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAStatusBarIcon.h"
#import "IAFunctions.h"

enum status_bar_icon_status {
    status_bar_icon_normal = 0,
    status_bar_icon_clicked = 1,
};

@implementation IAStatusBarIcon

@synthesize isHighlighted = _is_highlighted;

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _drag_types = [NSArray arrayWithObjects:NSFilenamesPboardType,
                                                nil];
        [self registerForDraggedTypes:_drag_types];
    }
    
    return self;
}

- (id)initWithDelegate:(id<IAStatusBarIconProtocol>)delegate statusItem:(NSStatusItem*)status_item
{
    if (self = [super init])
    {
        _delegate = delegate;
        _icon[status_bar_icon_normal] = [IAFunctions imageNamed:@"status_bar_icon_normal"];
        _icon[status_bar_icon_clicked] = [IAFunctions imageNamed:@"status_bar_icon_clicked"];
        CGFloat width = [status_item length];
        CGFloat height = [[NSStatusBar systemStatusBar] thickness];
        NSRect rect = NSMakeRect(0.0, 0.0, width, height);
        self = [self initWithFrame:rect];
        [self setNeedsDisplay:YES];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (_is_highlighted)
    {
        [[NSColor selectedMenuItemColor] set];
        [NSBezierPath fillRect:self.bounds];
    }
    
    NSImage* icon = _is_highlighted ? _icon[status_bar_icon_clicked] : _icon[status_bar_icon_normal];
    CGFloat x = roundf((NSWidth(self.bounds) - icon.size.width) / 2);
    CGFloat y = roundf((NSHeight(self.bounds) - icon.size.height) / 2);
    [icon drawAtPoint:NSMakePoint(x, y)
             fromRect:self.bounds
            operation:NSCompositeSourceOver
             fraction:1.0];
}

- (void)setHighlighted:(BOOL)is_highlighted
{
    _is_highlighted = is_highlighted;
    [self setNeedsDisplay:YES];
}

//- General Functions ------------------------------------------------------------------------------


//- Click Operations -------------------------------------------------------------------------------

- (void)mouseDown:(NSEvent*)theEvent
{
	[_delegate statusBarIconClicked:self];
}

//- Drag Operations --------------------------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste_board = sender.draggingPasteboard;
    if ([paste_board availableTypeFromArray:_drag_types])
    {
        [_delegate statusBarIconDragEntered:self];
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste_board = sender.draggingPasteboard;
    if (![paste_board availableTypeFromArray:_drag_types])
        return NO;
    
    NSArray* files = [paste_board propertyListForType:NSFilenamesPboardType];
    
    if (files.count > 0)
        [_delegate statusBarIconDragDrop:self withFiles:files];
    
    return YES;
}

@end
