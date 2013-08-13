//
//  IAFavouritesViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/13/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAFavouritesSendViewController.h"

@interface IAFavouritesSendViewController ()
@end

//- Favourites Window ------------------------------------------------------------------------------

@interface IAFavouritesWindow : NSWindow
@end

@implementation IAFavouritesWindow

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

@end

//- Favourites View ---------------------------------------------------------------------------------

@interface IAFavouritesView : NSView
@end

@implementation IAFavouritesView
{
@private
    NSArray* _drag_types;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        _drag_types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
        [self registerForDraggedTypes:_drag_types];
    }
    return self;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste_board = sender.draggingPasteboard;
    if (![paste_board availableTypeFromArray:_drag_types])
        return NO;
    
    NSArray* files = [paste_board propertyListForType:NSFilenamesPboardType];
    
    if (files.count > 0)
    {
        // Do something
    }
    
    return YES;
}

@end

//- Favourites Send View Controller ----------------------------------------------------------------

@implementation IAFavouritesSendViewController
{
    id<IAFavouritesSendViewProtocol> _delegate;
    NSArray* _favourites;
    NSWindow* _window;
    NSSize _favourite_size;
}

//- Initialisation ---------------------------------------------------------------------------------

+ (IAFavouritesWindow*)windowWithFrame:(NSRect)frame
{
    IAFavouritesWindow* result = [[IAFavouritesWindow alloc] initWithContentRect:frame
                                                             styleMask:NSBorderlessWindowMask
                                                               backing:NSBackingStoreBuffered
                                                                 defer:YES];
    result.alphaValue = 0.0;
	result.backgroundColor = [NSColor clearColor];
    result.hasShadow = YES;
	result.opaque = NO;
    [result setLevel:NSFloatingWindowLevel];
    [result setMovableByWindowBackground:YES];
    return result;
}

- (id)initWithDelegate:(id<IAFavouritesSendViewProtocol>)delegate
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _favourites = [_delegate favouritesViewWantsFavourites:self];
        _favourite_size = NSMakeSize(65.0, 65.0);
    }
    return self;
}

- (NSString*)description
{
    return @"[FavouritesSendView]";
}

- (void)loadView
{
    [super loadView];
}

//- General Functions ------------------------------------------------------------------------------

// Function to calculate position of bottom left corner of each favourite based on their number
- (NSRect)favouritePosition:(NSInteger)number of:(NSInteger)total
{
    NSSize frame_size = self.view.frame.size;
    // Select aribitrary arc radius
    CGFloat arc_radius = 1.25 * frame_size.height;
    // Calculate maximum angle that we can use for displaying favourites
    CGFloat arc_angle = 2.0 * asin((frame_size.width - _favourite_size.width) / (2.0 * arc_radius));
    // Calculate the angle around the x-axis of the circle
    CGFloat start_angle = - (0.5 * arc_angle);
    // Find the difference in angle between each view
    CGFloat delta = 0.0;
    if (total > 1)
        delta = arc_angle / (total - 1);
    else
        start_angle = 0.0;
    // End coordinates are rotated by 90º
    CGFloat y = arc_radius * cos(start_angle + (number * delta)) - (0.5 * _favourite_size.width);
    CGFloat x = arc_radius * sin(start_angle + (number * delta)) - (0.5 * _favourite_size.height);
    // Move coordinates into frame
    x += 0.5 * frame_size.width;
    y -= arc_radius - frame_size.height - 0.5 * _favourite_size.height;
    y = frame_size.height - y;
    return NSMakeRect(x, y, _favourite_size.width, _favourite_size.height);
}

- (void)addFavouriteSubViews
{
    for (NSInteger i = 0; i < 1; i++)
    {
        IAFavouriteView* favourite_view = [[IAFavouriteView alloc] initWithFrame:
                                           NSMakeRect(0.0,
                                                      0.0,
                                                      _favourite_size.width,
                                                      _favourite_size.height)];
        [self.view addSubview:favourite_view];
        [favourite_view setFrame:[self favouritePosition:i of:1]];
    }
}

- (void)showFavourites
{
    if (_window != nil)
        return;
    
    NSRect frame = NSZeroRect;
    frame.size = self.view.bounds.size;
    NSPoint midpoint = [_delegate favouritesViewWantsMidpoint:self];
    frame.origin = NSMakePoint(midpoint.x - (self.view.frame.size.width / 2.0),
                               midpoint.y - self.view.frame.size.height);
    
    _window = [IAFavouritesSendViewController windowWithFrame:frame];
    _window.alphaValue = 0.0;
    _window.delegate = self;
    _window.contentView = self.view;
    [self addFavouriteSubViews];
    
    [_window makeKeyAndOrderFront:nil];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [_window.animator setAlphaValue:1.0];
     }
                        completionHandler:^
     {
     }];
}

@end
