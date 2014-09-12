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
  __weak id<IAFavouritesSendViewProtocol> _delegate;
  NSMutableArray* _favourite_views;
  NSWindow* _window;
  NSSize _favourite_size;
  NSSize _link_size;
  NSPoint _start_pos;
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

- (void)setDelegate:(id<IAFavouritesSendViewProtocol>)delegate
{
  _delegate = delegate;
}

- (void)loadView
{
  [super loadView];
  _start_pos = NSMakePoint((NSWidth(self.view.frame) - _favourite_size.width) / 2.0,
                           NSHeight(self.view.frame));
}

//- General Functions ------------------------------------------------------------------------------

static CGFloat margin = 5.f;
static NSSize favourites_size = {430.f, 170.f};

- (NSRect)favourites_area
{
  NSPoint offset = NSMakePoint(floor((self.view.frame.size.width - favourites_size.width) / 2.0),
                               floor(self.view.frame.size.height - favourites_size.width));
  NSRect res = {
    .origin = offset,
    .size = favourites_size
  };
  return res;
}

// Function to calculate position of bottom left corner of each favourite based on their number
- (NSRect)favouritePosition:(NSInteger)number
                         of:(NSInteger)total
{
  // Select aribitrary arc radius
  CGFloat arc_radius = 1.25 * self.favourites_area.size.height;
  // Calculate maximum angle that we can use for displaying favourites
  CGFloat arc_angle = 2.0 * asin((self.favourites_area.size.width - _favourite_size.width) / (2.0 * arc_radius));
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
  x += 0.5 * self.favourites_area.size.width + self.favourites_area.origin.x + margin;
  y -= arc_radius - self.favourites_area.size.height - 0.75 * _favourite_size.height;
  y = self.favourites_area.size.height - self.favourites_area.origin.y - y;

  NSRect res = NSMakeRect(x, y, _favourite_size.width, _favourite_size.height);
  return res;
}

- (void)addSubViewsForFavourites:(NSArray*)favourites
{
  NSRect favourite_rect = NSMakeRect(_start_pos.x, _start_pos.y,
                                     _favourite_size.width, _favourite_size.height);
  for (IAUser* favourite in favourites)
  {
    IAFavouriteView* favourite_view = [[IAFavouriteView alloc] initWithFrame:favourite_rect
                                                                 andDelegate:self.favourites_view
                                                                     andUser:favourite];
    [_favourite_views addObject:favourite_view];
    [self.favourites_view addSubview:favourite_view];
  }

  NSRect link_rect = NSMakeRect(_start_pos.x, _start_pos.y, _link_size.width, _link_size.height);
  _link_view = [[InfinitLinkShortcutView alloc] initWithFrame:link_rect
                                                  andDelegate:self.favourites_view];
  [self.favourites_view addSubview:_link_view];

  CGFloat diff_x = (_favourite_size.width - _link_size.width) / 2.0;
  NSPoint link_pos =
    NSMakePoint((self.favourites_area.size.width - _link_size.width) / 2.0 + self.favourites_area.origin.x + diff_x,
                (self.favourites_area.size.height - _link_size.height) / 2.0 + 40.0 - self.favourites_area.origin.y);

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.3;
     context.timingFunction =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
     [_link_view.animator setFrameOrigin:link_pos];
     NSInteger i = 0;
     for (IAFavouriteView* fav_view in _favourite_views)
     {
       [fav_view.animator setFrame:[self favouritePosition:i++ of:favourites.count]];
     }
   }
                      completionHandler:^
   {
     [_link_view setFrameOrigin:link_pos];
     NSInteger i = 0;
     for (IAFavouriteView* fav_view in _favourite_views)
     {
       [fav_view setFrame:[self favouritePosition:i++ of:favourites.count]];
     }
   }];
}

- (void)showFavourites
{
  if (_window != nil || _open)
    return;

  _open = YES;
  
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
  
  // XXX For now we only handle up to 5 favourites
  NSArray* favourites;
  if (temp_arr.count > 5)
    favourites = [temp_arr subarrayWithRange:NSMakeRange(0, 5)];
  else
    favourites = [NSArray arrayWithArray:temp_arr];
  
  NSRect frame = NSZeroRect;
  frame.size = self.view.bounds.size;
  NSPoint midpoint = [_delegate favouritesViewWantsMidpoint:self];
  NSPoint origin = NSMakePoint(midpoint.x - NSWidth(self.view.frame) / 2.0 - 5.0,
                               midpoint.y - NSHeight(self.view.frame));

  CGFloat x_screen_edge =
  [NSScreen mainScreen].frame.origin.x + [NSScreen mainScreen].frame.size.width;
  if (origin.x + (NSWidth(self.view.frame) / 2.0) > x_screen_edge)
    origin.x = x_screen_edge - (NSWidth(self.view.frame) / 2.0) - 10.0;

  frame.origin = origin;

  [self.favourites_view setDelegate:self];
  for (NSView* view in _favourites_view.subviews)
  {
    [view removeFromSuperview];
  }
  
  _window = [IAFavouritesSendViewController windowWithFrame:frame];
  _window.alphaValue = 0.0;
  _window.delegate = self;
  _window.contentView = self.view;
  
  [_window makeKeyAndOrderFront:nil];

  [self addSubViewsForFavourites:favourites];
  
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
  [self hideFavouritesExcluding:nil];
}

- (void)hideFavouritesExcluding:(NSView*)excluded_view
{
  if (_window == nil || !_open)
    return;

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.2;
     if (excluded_view != _link_view)
     {
       [_link_view.animator setFrameOrigin:_start_pos];
     }
     for (IAFavouriteView* fav_view in _favourite_views)
     {
       if (excluded_view != fav_view)
       {
         [fav_view.animator setFrameOrigin:_start_pos];
       }
     }
   }
                      completionHandler:^
   {
     if (excluded_view != _link_view)
     {
       [_link_view setFrameOrigin:_start_pos];
     }
     for (IAFavouriteView* fav_view in _favourite_views)
     {
       if (excluded_view != fav_view)
       {
         [fav_view setFrameOrigin:_start_pos];
       }
     }
     [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
      {
        context.duration = 0.1;
        [_window.animator setAlphaValue:0.0];
      }
                         completionHandler:^
      {
        _open = NO;
        [_window orderOut:nil];
        _window.delegate = nil;
        _window = nil;
        for (IAFavouriteView* fav_view in _favourite_views)
          [fav_view removeFromSuperview];
        [_link_view removeFromSuperview];
        [_favourite_views removeAllObjects];
        [_favourites_view setDelegate:nil];
      }];
   }];
}

- (void)resetTimeout
{
  [_favourites_view resetTimeout];
}

//- Favourites View Protocol -----------------------------------------------------------------------

- (void)favouritesViewHadDragExit:(IAFavouritesView*)sender
{
  [_delegate favouritesViewWantsClose:self];
}

- (void)favouriteView:(IAFavouriteView*)sender
        gotDropOnUser:(IAUser*)user
            withFiles:(NSArray*)files
{
  CGFloat end_size = 250.0;
  NSRect end_rect = NSMakeRect(sender.frame.origin.x - ((end_size - sender.frame.size.width) / 2.0),
                               sender.frame.origin.y - ((end_size - sender.frame.size.height) / 2.0),
                               end_size, end_size);
  [self hideFavouritesExcluding:sender];
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.2;
    [sender.animator setFrame:end_rect];
    [sender.animator setAlphaValue:0.0];
  }
                      completionHandler:^
  {
    [_delegate favouritesView:self gotDropOnUser:user withFiles:files];
  }];
}

- (void)linkViewGotDrop:(InfinitLinkShortcutView*)sender
              withFiles:(NSArray*)files
{
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_FAVOURITES_LINK_DROP];
  CGFloat end_size = 175.0;
  NSRect end_rect = NSMakeRect(sender.frame.origin.x - ((end_size - sender.frame.size.width) / 2.0),
                               sender.frame.origin.y - ((end_size - sender.frame.size.height) / 2.0),
                               end_size, end_size);
  [self hideFavouritesExcluding:sender];
  if ([IAFunctions osxVersion] == INFINIT_OS_X_VERSION_10_7)
    [_delegate favouritesView:self gotDropLinkWithFiles:files];
  else
  {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
       context.duration = 0.2;
       [sender.animator setFrame:end_rect];
       [sender.animator setAlphaValue:0.0];
     }
                        completionHandler:^
     {
       [_delegate favouritesView:self gotDropLinkWithFiles:files];
     }];
  }
}

@end
