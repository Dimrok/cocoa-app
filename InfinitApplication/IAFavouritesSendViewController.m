//
//  IAFavouritesViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/13/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAFavouritesSendViewController.h"

#import "InfinitMetricsManager.h"

#import <QuartzCore/QuartzCore.h>

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

//- Favourites Send View Controller ----------------------------------------------------------------

@implementation IAFavouritesSendViewController
{
  id<IAFavouritesSendViewProtocol> _delegate;
  NSArray* _favourites;
  NSMutableArray* _favourite_views;
  NSWindow* _window;
  NSSize _favourite_size;
  NSSize _link_size;
  NSPoint _start_pos;
  BOOL _window_open;
  InfinitLinkShortcutView* _link_view;
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
  result.hasShadow = NO;
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
    _favourite_views = [NSMutableArray array];
    _favourite_size = NSMakeSize(80.0, 80.0);
    _link_size = NSMakeSize(70.0, 70.0);
  }
  return self;
}

- (void)loadView
{
  [super loadView];
  _start_pos = NSMakePoint((NSWidth(self.view.frame) - _favourite_size.width) / 2.0,
                           NSHeight(self.view.frame));
}

//- General Functions ------------------------------------------------------------------------------

// Function to calculate position of bottom left corner of each favourite based on their number
- (NSRect)favouritePosition:(NSInteger)number of:(NSInteger)total
{
  // Leave a margin on the sides of the view
  CGFloat margin = 5.0;
  NSSize frame_size = NSMakeSize(NSWidth(self.view.frame) - 2 * margin,
                                 NSHeight(self.view.frame));
  // Select aribitrary arc radius
  CGFloat arc_radius = 1.25 * frame_size.height;
  // Calculate maximum angle that we can use for displaying favourites
  CGFloat arc_angle = 2.0 * asin((frame_size.width - _favourite_size.width) / (2.0 * arc_radius));
  // Calculate the angle around the x-axis of the circle
  CGFloat start_angle = - (0.5 * arc_angle);
  // Find the difference in angle between each view
  CGFloat delta = 0.0;
  if (total == 2)
  {
    delta = arc_angle / 2;
    start_angle = - delta / 2.0;
  }
  else if (total > 2)
  {
    delta = arc_angle / (total - 1);
  }
  else
  {
    start_angle = 0.0;
  }
  // End coordinates are rotated by 90º
  CGFloat y = arc_radius * cos(start_angle + (number * delta)) - (0.5 * _favourite_size.width);
  CGFloat x = arc_radius * sin(start_angle + (number * delta)) - (0.5 * _favourite_size.width);
  // Move coordinates into frame
  x += 0.5 * frame_size.width + margin;
  y -= arc_radius - frame_size.height - 0.45 * _favourite_size.height;
  y = frame_size.height - y;
  return NSMakeRect(x, y, _favourite_size.width, _favourite_size.height);
}

- (void)addSubViews
{
  NSRect favourite_rect = NSMakeRect(_start_pos.x, _start_pos.y,
                                     _favourite_size.width, _favourite_size.height);
  for (IAUser* favourite in _favourites)
  {
    IAFavouriteView* favourite_view = [[IAFavouriteView alloc] initWithFrame:favourite_rect
                                                                 andDelegate:self.favourites_view
                                                                     andUser:favourite];
    [self.favourites_view addSubview:favourite_view];
    [_favourite_views addObject:favourite_view];
  }

  NSRect link_rect = NSMakeRect(_start_pos.x, _start_pos.y, _link_size.width, _link_size.height);
  _link_view = [[InfinitLinkShortcutView alloc] initWithFrame:link_rect
                                                  andDelegate:self.favourites_view];
  [self.favourites_view addSubview:_link_view];

  NSPoint link_pos =
    NSMakePoint((NSWidth(self.favourites_view.frame) - _link_size.width) / 2.0,
                (NSHeight(self.favourites_view.frame) - _link_size.height) / 2.0 + 40.0);

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.3;
     context.timingFunction =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
     [_link_view.animator setFrameOrigin:link_pos];
     NSInteger i = 0;
     for (IAFavouriteView* fav_view in _favourite_views)
     {
       [fav_view.animator setFrame:[self favouritePosition:i++ of:_favourites.count]];
     }
   }
                      completionHandler:^
   {
     [_link_view setFrameOrigin:link_pos];
     NSInteger i = 0;
     for (IAFavouriteView* fav_view in _favourite_views)
     {
       [fav_view setFrame:[self favouritePosition:i++ of:_favourites.count]];
     }
   }];
}

- (void)showFavourites
{
  if (_window != nil || _window_open)
    return;
  
  _window_open = YES;
  
  NSMutableArray* temp_arr =
    [NSMutableArray arrayWithArray:[_delegate favouritesViewWantsFavourites:self]];
  // If we don't have favourites, add some swaggers
  if (temp_arr.count < 5)
  {
    NSArray* swaggers = [_delegate favouritesViewWantsSwaggers:self];
    
    for (IAUser* swagger in swaggers)
    {
      if (!swagger.deleted && !swagger.ghost && temp_arr.count < 5 && ![temp_arr containsObject:swagger])
        [temp_arr addObject:swagger];
    }
  }
  
  if (temp_arr.count == 0)
    return;
  
  // XXX For now we only handle up to 5 favourites
  if (temp_arr.count > 5)
    _favourites = [temp_arr subarrayWithRange:NSMakeRange(0, 5)];
  else
    _favourites = [NSArray arrayWithArray:temp_arr];
  
  NSRect frame = NSZeroRect;
  frame.size = self.view.bounds.size;
  NSPoint midpoint = [_delegate favouritesViewWantsMidpoint:self];
  frame.origin = NSMakePoint(midpoint.x - NSWidth(self.view.frame) / 2.0,
                             midpoint.y - NSHeight(self.view.frame));
  
  [self.favourites_view setDelegate:self];
  
  _window = [IAFavouritesSendViewController windowWithFrame:frame];
  _window.alphaValue = 0.0;
  _window.delegate = self;
  _window.contentView = self.view;
  
  [_window makeKeyAndOrderFront:nil];

  [self addSubViews];
  
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.1;
     [_window.animator setAlphaValue:1.0];
   }
                      completionHandler:^
   {
     [_window setAlphaValue:1.0];
   }];
}

- (void)hideFavourites
{
  if (_window == nil || !_window_open)
    return;
  
  _window_open = NO;
  
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.2;
     [_link_view.animator setFrameOrigin:_start_pos];
     for (IAFavouriteView* fav_view in _favourite_views)
     {
       [fav_view.animator setFrameOrigin:_start_pos];
     }
   }
                      completionHandler:^
   {
     [_link_view setFrameOrigin:_start_pos];
     for (IAFavouriteView* fav_view in _favourite_views)
     {
       [fav_view setFrameOrigin:_start_pos];
     }
     [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
      {
        context.duration = 0.1;
        [_window.animator setAlphaValue:0.0];
      }
                         completionHandler:^
      {
        [_window orderOut:nil];
        _window.delegate = nil;
        _window = nil;
        for (IAFavouriteView* fav_view in _favourite_views)
          [fav_view removeFromSuperview];
        _favourite_views = nil;
      }];
   }];
}

//- Favourites View Protocol -----------------------------------------------------------------------

- (void)favouritesViewHadDragExit:(IAFavouritesView*)sender
{
  [_delegate favouritesViewWantsClose:self];
}

- (void)favouritesView:(IAFavouritesView*)sender
         gotDropOnUser:(IAUser*)user
             withFiles:(NSArray*)files
{
  [_delegate favouritesView:self
              gotDropOnUser:user
                  withFiles:files];
}

- (void)linkViewGotDrop:(InfinitLinkShortcutView*)sender
              withFiles:(NSArray*)files
{
  [_delegate favouritesView:self gotDropLinkWithFiles:files];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_FAVOURITES_LINK_DROP];
  
}

@end
