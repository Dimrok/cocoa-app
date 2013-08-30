//
//  IAStatusBarIcon.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAStatusBarIcon.h"
#import "IAFunctions.h"

typedef enum IAStatusBarIconStatus {
    STATUS_BAR_ICON_NORMAL = 0,
    STATUS_BAR_ICON_FIRE,
    STATUS_BAR_ICON_CLICKED,
    STATUS_BAR_ICON_NO_CONNECTION,
} IAStatusBarIconStatus;

@implementation IAStatusBarIcon
{
@private
    id _delegate;
    NSArray* _drag_types;
    NSImage* _icon[4];
    NSImageView* _icon_view;
    BOOL _is_highlighted;
    gap_UserStatus _connected;
    NSInteger _number_of_items;
}

@synthesize isHighlighted = _is_highlighted;

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _drag_types = [NSArray arrayWithObjects:NSFilenamesPboardType,
                                                nil];
        _number_of_items = 0;
        _connected = gap_user_status_offline;
        [self registerForDraggedTypes:_drag_types];
    }
    
    return self;
}

- (id)initWithDelegate:(id<IAStatusBarIconProtocol>)delegate statusItem:(NSStatusItem*)status_item
{
    if (self = [super init])
    {
        _delegate = delegate;
        _icon[STATUS_BAR_ICON_NORMAL] = [IAFunctions imageNamed:@"status_bar_icon_normal"];
        _icon[STATUS_BAR_ICON_FIRE] = [IAFunctions imageNamed:@"status_bar_icon_fire"];
        _icon[STATUS_BAR_ICON_CLICKED] = [IAFunctions imageNamed:@"status_bar_icon_clicked"];
        _icon[STATUS_BAR_ICON_NO_CONNECTION] = [IAFunctions
                                                imageNamed:@"icon_status_bar_no_connection"];
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
    
    NSImage* icon;
    if (_is_highlighted)
        icon = _icon[STATUS_BAR_ICON_CLICKED];
    else if (_connected == gap_user_status_offline)
        icon = _icon[STATUS_BAR_ICON_NO_CONNECTION];
    else if (_number_of_items > 0)
        icon = _icon[STATUS_BAR_ICON_FIRE];
    else
        icon = _icon[STATUS_BAR_ICON_NORMAL];
    CGFloat x = roundf((NSWidth(self.bounds) - icon.size.width) / 2);
    CGFloat y = roundf((NSHeight(self.bounds) - icon.size.height) / 2);
    [icon drawAtPoint:NSMakePoint(x, y)
             fromRect:self.bounds
            operation:NSCompositeSourceOver
             fraction:1.0];
    if (_number_of_items > 0)
    {
        NSDictionary* style;
        if (_is_highlighted)
        {
            style = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                    paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                            colour:IA_GREY_COLOUR(255.0)
                                            shadow:nil];
        }
        else
        {
            style = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                    paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                            colour:IA_RGB_COLOUR(221.0, 0.0, 0.0)
                                            shadow:nil];
        }
        NSString* number_str = _number_of_items > 9 ?
                    @"+" : [[NSNumber numberWithInteger:_number_of_items] stringValue];
        NSAttributedString* notifications_str = [[NSAttributedString alloc]
                                                            initWithString:number_str
                                                                attributes:style];
        [notifications_str drawAtPoint:
            NSMakePoint(self.bounds.size.width - notifications_str.size.width, 10.0)];
    }
}

//- General Functions ------------------------------------------------------------------------------

- (void)setConnected:(gap_UserStatus)connected
{
    _connected = connected;
    [self setNeedsDisplay:YES];
}

- (void)setHighlighted:(BOOL)is_highlighted
{
    _is_highlighted = is_highlighted;
    [self setNeedsDisplay:YES];
}

- (void)setNumberOfItems:(NSInteger)number_of_items
{
    _number_of_items = number_of_items;
    [self setNeedsDisplay:YES];
}

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
