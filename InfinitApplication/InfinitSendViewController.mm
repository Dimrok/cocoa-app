//
//  InfinitSendViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendViewController.h"

#import "InfinitMetricsManager.h"
#import <QuartzCore/QuartzCore.h>

//- User Link View ---------------------------------------------------------------------------------

@implementation InfinitSendUserLinkView
{
@private
  id<InfinitSendUserLinkProtocol> _delegate;
  NSTrackingArea* _tracking_area;
  NSString* _link_str;
  NSString* _user_str;
  NSDictionary* _norm_attrs;
  NSDictionary* _high_attrs;
}

- (void)setupView
{
  NSFont* font = [NSFont fontWithName:@"Montserrat" size:11.0];
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSCenterTextAlignment;
  _norm_attrs = [IAFunctions textStyleWithFont:font
                                paragraphStyle:para
                                        colour:IA_GREY_COLOUR(32.0)
                                        shadow:nil];
  _high_attrs = [IAFunctions textStyleWithFont:font
                                paragraphStyle:para
                                        colour:IA_RGB_COLOUR(0, 195, 192)
                                        shadow:nil];
  _link_str = NSLocalizedString(@"GET A LINK", nil);
  _user_str = NSLocalizedString(@"SEND TO USER", nil);
  self.user_text.attributedStringValue =
    [[NSAttributedString alloc] initWithString:_user_str attributes:_high_attrs];
  self.link_text.attributedStringValue =
    [[NSAttributedString alloc] initWithString:_link_str attributes:_norm_attrs];
}

- (void)setDelegate:(id<InfinitSendUserLinkProtocol>)delegate
{
  _delegate = delegate;
}

- (BOOL)isOpaque
{
  return NO;
}

- (void)dealloc
{
  _tracking_area = nil;
}

- (void)setAnimate_mode:(CGFloat)animate_mode
{
  _animate_mode = animate_mode;
  [self setNeedsDisplay:YES];
}

- (void)setMode:(InfinitUserLinkMode)mode
{
  if (_mode == mode)
    return;
  _mode = mode;
  CGFloat val;
  if (_mode == INFINIT_USER_MODE)
  {
    self.user_text.attributedStringValue =
      [[NSAttributedString alloc] initWithString:_user_str attributes:_high_attrs];
    self.link_text.attributedStringValue =
      [[NSAttributedString alloc] initWithString:_link_str attributes:_norm_attrs];
    val = 0.0;
  }
  else
  {
    self.user_text.attributedStringValue =
      [[NSAttributedString alloc] initWithString:_user_str attributes:_norm_attrs];
    self.link_text.attributedStringValue =
      [[NSAttributedString alloc] initWithString:_link_str attributes:_high_attrs];
    val = 1.0;
  }

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
  {
    context.timingFunction =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
   [self.animator setAnimate_mode:val];
  }
                     completionHandler:^
  {
    _animate_mode = val;
  }];
}

//- Animation --------------------------------------------------------------------------------------

+ (id)defaultAnimationForKey:(NSString*)key
{
  if ([key isEqualToString:@"animate_mode"])
    return [CABasicAnimation animation];

  return [super defaultAnimationForKey:key];
}

//- Mouse Handling ---------------------------------------------------------------------------------

- (void)resetCursorRects
{
  [super resetCursorRects];
  NSCursor* cursor = [NSCursor pointingHandCursor];
  [self addCursorRect:self.bounds cursor:cursor];
}


- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];

  [self addTrackingArea:_tracking_area];

  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
  else
    [self mouseExited:nil];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
}

- (void)mouseExited:(NSEvent*)theEvent
{
}

- (void)mouseDown:(NSEvent*)theEvent
{
  NSPoint click_loc = theEvent.locationInWindow;
  if (click_loc.x < self.bounds.size.width / 2.0)
    [_delegate gotUserClick:self];
  else
    [_delegate gotLinkClick:self];
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* bg = [IAFunctions roundedTopBezierWithRect:self.bounds cornerRadius:6.0];
  [IA_GREY_COLOUR(255) set];
  [bg fill];
  NSBezierPath* light_line =
    [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0, NSWidth(self.bounds), 2.0)];
  [IA_GREY_COLOUR(230) set];
  [light_line fill];
  NSRect dark_rect = {
    .origin = NSMakePoint((NSWidth(self.bounds) / 2.0) * _animate_mode, 0.0),
    .size = NSMakeSize(NSWidth(self.bounds) / 2.0, 2.0)
  };
  NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:dark_rect];
  [IA_RGB_COLOUR(0, 195, 192) set];
  [dark_line fill];
}

@end

//- Controller -------------------------------------------------------------------------------------

@interface InfinitSendViewController ()
@end

@implementation InfinitSendViewController
{
@private
  id<InfinitSendViewProtocol> _delegate;

  NSDictionary* _file_count_attrs;

  IAUserSearchViewController* _search_controller;
  InfinitSendNoteViewController* _note_controller;
  InfinitSendFilesViewController* _files_controller;

  NSArray* _recipient_list;
  NSString* _note;
  CGFloat _last_search_height;
}

- (id)initWithDelegate:(id<InfinitSendViewProtocol>)delegate
  withSearchController:(IAUserSearchViewController*)search_controller;
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    NSShadow* file_count_shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                                     blurRadius:1.0
                                                         colour:IA_GREY_COLOUR(0.0)];
    NSFont* small_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                    traits:NSUnboldFontMask
                                                                    weight:0
                                                                      size:10.0];
    _file_count_attrs = [IAFunctions textStyleWithFont:small_font
                                        paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                colour:IA_GREY_COLOUR(255.0)
                                                shadow:file_count_shadow];
    _search_controller = search_controller;
    [_search_controller setDelegate:self];
    _note_controller = [[InfinitSendNoteViewController alloc] initWithDelegate:self];
    _files_controller = [[InfinitSendFilesViewController alloc] initWithDelegate:self];
    [self.user_link_view setDelegate:self];
  }
  return self;
}

- (void)awakeFromNib
{
  [self.search_view addSubview:_search_controller.view];
  [self.search_view addConstraints:[NSLayoutConstraint
                                    constraintsWithVisualFormat:@"V:|[search_view]|"
                                    options:0
                                    metrics:nil
                                    views:@{@"search_view": _search_controller.view}]];
  [self.note_view addSubview:_note_controller.view];
  [self.note_view addConstraints:[NSLayoutConstraint
                                  constraintsWithVisualFormat:@"V:|[note_view]|"
                                  options:0
                                  metrics:nil
                                  views:@{@"note_view": _note_controller.view}]];
  [self.files_view addSubview:_files_controller.view];
  [self.files_view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|[files_view]|"
                                   options:0
                                   metrics:nil
                                   views:@{@"files_view": _files_controller.view}]];
  _search_controller.open = YES;
}

- (void)loadView
{
  [_files_controller updateWithFiles:[_delegate sendViewWantsFileList:self]];
  [super loadView];
  [self setSendButtonState];
  [self.user_link_view setDelegate:self];
  [self.user_link_view setupView];
  [self performSelector:@selector(delayedCursorInSearch) withObject:nil afterDelay:0.2];
}

- (void)delayedCursorInSearch
{
  [self.view.window makeFirstResponder:_search_controller.search_field];
  [_search_controller.search_field.currentEditor moveToEndOfLine:nil];
}

- (void)setSendButtonState
{
  if ([self inputsGood])
    [self.send_button setEnabled:YES];
  else
    [self.send_button setEnabled:NO];
}

- (void)filesUpdated
{
  NSArray* files = [_delegate sendViewWantsFileList:self];
  [_files_controller updateWithFiles:files];
  NSString* count_str;
  if (files.count > 99)
    count_str = @"+";
  else
    count_str = [NSString stringWithFormat:@"%lu", files.count];
  self.file_count.attributedStringValue =
    [[NSAttributedString alloc] initWithString:count_str attributes:_file_count_attrs];
  [self setSendButtonState];
  if (!_files_controller.open)
    [_files_controller showFiles];
}

- (BOOL)inputsGood
{
  NSMutableArray* recipients = [NSMutableArray arrayWithArray:[_search_controller recipientList]];
  [_search_controller checkInputs];
  if (recipients.count == 0)
    return NO;

  NSArray* files = [_delegate sendViewWantsFileList:self];
  if (files.count == 0)
    return NO;

  _recipient_list = [NSArray arrayWithArray:recipients];

  for (id object in _recipient_list)
  {
    if ([object isKindOfClass:NSString.class] && ![IAFunctions stringIsValidEmail:object] &&
        ![object isKindOfClass:IAUser.class])
    {
      return NO;
    }
  }

  _note = _note_controller.note;
  if (_note.length > 100)
    _note = [_note substringWithRange:NSMakeRange(0, 100)];

  return YES;
}

- (void)doSend
{
  NSMutableArray* destinations = [NSMutableArray array];
  for (id element in _recipient_list)
  {
    if ([element isKindOfClass:InfinitSearchElement.class])
    {
      if ([element user] == nil)
        [destinations addObject:[element email]];
      else
        [destinations addObject:[element user]];
    }
    else if ([element isKindOfClass:NSString.class])
    {
      [destinations addObject:element];
    }
  }
  NSArray* transaction_ids = [_delegate sendView:self
                                  wantsSendFiles:[_delegate sendViewWantsFileList:self]
                                         toUsers:destinations
                                     withMessage:_note];
  (void)transaction_ids;
}

//- User Interaction -------------------------------------------------------------------------------

- (IBAction)sendButtonClicked:(NSButton*)sender
{
  if ([self inputsGood])
    [self doSend];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_ADD_FILES];
}

- (IBAction)cancelButtonClicked:(NSButton*)sender
{
  [_delegate sendViewWantsCancel:self];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_SEND_TRASH];
}

//- Note Protocol ----------------------------------------------------------------------------------

- (void)noteViewWantsLoseFocus:(InfinitSendNoteViewController*)sender
{
  [self noteViewWantsHide:nil];
}

- (void)noteViewWantsShow:(InfinitSendNoteViewController*)sender
{
  _note_controller.open = YES;
  _search_controller.open = NO;
  if (self.user_link_view.mode == INFINIT_USER_MODE)
    _last_search_height = self.search_constraint.constant;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.075;
   }
                      completionHandler:^
   {
     [self.note_constraint.animator setConstant:_note_controller.height];
     if (self.user_link_view.mode == INFINIT_USER_MODE)
       [self.search_constraint.animator setConstant:NSHeight(_search_controller.search_box_view.frame)];
     [self.view.window makeFirstResponder:_note_controller.note_field];
     [[_note_controller.note_field currentEditor] moveToEndOfLine:nil];
   }];
}

- (void)noteViewWantsHide:(InfinitSendNoteViewController*)sender
{
  _note_controller.open = NO;
  _search_controller.open = YES;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.075;
   }
                      completionHandler:^
   {
     [self.note_constraint.animator setConstant:_note_controller.height];
     if (self.user_link_view.mode == INFINIT_USER_MODE)
     {
       [self.search_constraint.animator setConstant:_last_search_height];
       [self.view.window makeFirstResponder:_search_controller.search_field];
       [[_search_controller.search_field currentEditor] moveToEndOfLine:nil];
     }
   }];
}

//- Files Protocol ---------------------------------------------------------------------------------

- (void)fileList:(InfinitSendFilesViewController*)sender
wantsRemoveFileAtIndex:(NSInteger)index
{
  [_delegate sendView:self wantsRemoveFileAtIndex:index];
}

- (void)fileList:(InfinitSendFilesViewController*)sender
wantsChangeHeight:(CGFloat)height
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
   }
                      completionHandler:^
   {
     [self.files_constraint.animator setConstant:height];
   }];
}

- (void)fileListGotAddFilesClicked:(InfinitSendFilesViewController*)sender
{
  [_delegate sendViewWantsOpenFileDialogBox:self];
}

//- Search Protocol --------------------------------------------------------------------------------

- (void)searchView:(IAUserSearchViewController*)sender
   changedToHeight:(CGFloat)height
{
  _last_search_height = height;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
  {
  }
                      completionHandler:^
  {
    [self.search_constraint.animator setConstant:height];
  }];
}

- (BOOL)searchViewWantsIfGotFile:(IAUserSearchViewController*)sender
{
  if ([[_delegate sendViewWantsFileList:self] count] > 0)
    return YES;
  return NO;
}

- (void)searchViewWantsLoseFocus:(IAUserSearchViewController*)sender
{
  [self noteViewWantsShow:nil];
}

- (void)searchViewGotFocus:(IAUserSearchViewController*)sender
{
  if (_note_controller.open)
    [self noteViewWantsHide:nil];
}

- (void)searchView:(IAUserSearchViewController*)sender
 wantsAddFavourite:(IAUser*)user
{
  [_delegate sendView:self wantsAddFavourite:user];
}

- (void)searchView:(IAUserSearchViewController*)sender
wantsRemoveFavourite:(IAUser*)user
{
  [_delegate sendView:self wantsRemoveFavourite:user];
}

- (void)searchViewInputsChanged:(IAUserSearchViewController*)sender
{
  [self setSendButtonState];
}

- (void)searchViewGotWantsSend:(IAUserSearchViewController*)sender
{
  if ([self inputsGood])
    [self doSend];
}

- (NSArray*)searchViewWantsFriendsByLastInteraction:(IAUserSearchViewController*)sender
{
  return [_delegate sendViewWantsFriendsByLastInteraction:self];
}

//- User Link Protocol -----------------------------------------------------------------------------

- (void)gotUserClick:(InfinitSendUserLinkView*)sender
{
  [self.user_link_view setMode:INFINIT_USER_MODE];
  _note_controller.link_mode = NO;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
   {
   }
                      completionHandler:^
   {
     if (_search_controller.open)
       [self.search_constraint.animator setConstant:_last_search_height];
     else
       [self.search_constraint.animator setConstant:NSHeight(_search_controller.search_box_view.frame)];
   }];
}

- (void)gotLinkClick:(InfinitSendUserLinkView*)sender
{
  [self.user_link_view setMode:INFINIT_LINK_MODE];
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
  {
  }
                      completionHandler:^
  {
    [self.search_constraint.animator setConstant:0.0];
    _note_controller.link_mode = YES;
  }];
}

@end
