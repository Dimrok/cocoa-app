//
//  InfinitLinkShortcutView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 26/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkShortcutView.h"

@implementation InfinitLinkShortcutView
{
@private
  __weak id<InfinitLinkShortcutViewProtocol> _delegate;
  NSArray* _drag_types;
  BOOL _hover;
}

//- Initialisation ---------------------------------------------------------------------------------

static NSAttributedString* _link_text = nil;
static NSImage* _link_image_norm = nil;
static NSImage* _link_image_hover = nil;
static CGFloat _image_diameter;

- (id)initWithFrame:(NSRect)frameRect
        andDelegate:(id<InfinitLinkShortcutViewProtocol>)delegate
{
  if (self = [super initWithFrame:frameRect])
  {
    _delegate = delegate;
    _hover = NO;
    _drag_types = @[NSFilenamesPboardType];
    [self registerForDraggedTypes:_drag_types];
    if (_link_text == nil)
    {
      _image_diameter = 50.0;
      NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
      para.alignment = NSCenterTextAlignment;
      NSShadow* name_shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                                 blurRadius:2.0
                                                     colour:IA_GREY_COLOUR(0.0)];

      NSMutableDictionary* style = [NSMutableDictionary dictionaryWithDictionary:
                                    [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:13.0]
                                                    paragraphStyle:para
                                                            colour:IA_GREY_COLOUR(255.0)
                                                            shadow:name_shadow]];
      [style setValue:IA_GREY_COLOUR(0.0) forKey:NSStrokeColorAttributeName];
      [style setValue:@-0.25 forKey:NSStrokeWidthAttributeName];
      _link_text = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Link", nil)
                                                   attributes:style];

      NSImage* cloud_image =
        [[NSImage alloc] initWithSize:NSMakeSize(_image_diameter - 4.0, _image_diameter - 4.0)];
      [cloud_image lockFocus];

      NSRect bg_rect = {
        .origin = NSMakePoint(0.0, 0.0),
        .size = NSMakeSize(_image_diameter - 4.0, _image_diameter - 4.0)
      };
      NSBezierPath* bg = [NSBezierPath bezierPathWithOvalInRect:bg_rect];
      [IA_RGB_COLOUR(113, 113, 113) set];
      [bg fill];
      NSImage* icon = [IAFunctions imageNamed:@"icon-upload"];
      [icon drawAtPoint:NSMakePoint((_image_diameter - icon.size.width - 4.0) / 2.0,
                                    (_image_diameter - icon.size.height - 4.0) / 2.0)
               fromRect:NSZeroRect
              operation:NSCompositeSourceOver fraction:1.0];

      [cloud_image unlockFocus];
      _link_image_norm = [IAFunctions makeRoundAvatar:cloud_image
                                           ofDiameter:_image_diameter
                                withBorderOfThickness:2.0
                                             inColour:IA_RGBA_COLOUR(255, 255, 255, 0.8)
                                    andShadowOfRadius:4.0];

      _link_image_hover = [IAFunctions makeRoundAvatar:cloud_image
                                            ofDiameter:_image_diameter
                                 withBorderOfThickness:2.0
                                              inColour:IA_GREY_COLOUR(255.0)
                                     andShadowOfRadius:4.0];
    }
  }
  return self;
}

- (BOOL)isOpaque
{
  return NO;
}

- (CGFloat)link_image_diameter
{
  return (self.frame.size.width - 20.0);
}

- (void)drawRect:(NSRect)dirtyRect
{
  NSImage* image;
  if (_hover)
    image = _link_image_hover;
  else
    image = _link_image_norm;

  CGFloat avatar_w_diff = NSWidth(self.bounds) - self.link_image_diameter;
  NSRect image_rect = NSMakeRect(self.bounds.origin.x + (avatar_w_diff / 2.0),
                                 self.bounds.origin.y + NSHeight(self.bounds) - self.link_image_diameter,
                                 self.link_image_diameter,
                                 self.link_image_diameter);

  [image drawInRect:image_rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

  CGFloat name_w_diff = NSWidth(self.bounds) - _link_text.size.width;
  [_link_text drawAtPoint:NSMakePoint(self.bounds.origin.x + (name_w_diff / 2.0),
                                      self.bounds.origin.y)];
}

//- Drag Operations --------------------------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if ([paste_board availableTypeFromArray:_drag_types])
  {
    [_delegate linkViewGotDragEnter:self];
    _hover = YES;
    [self setNeedsDisplay:YES];
    return NSDragOperationCopy;
  }
  return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
  [_delegate linkViewGotDragExit:self];
  _hover = NO;
  [self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if (![paste_board availableTypeFromArray:_drag_types])
    return NO;

  NSArray* files = [paste_board propertyListForType:NSFilenamesPboardType];

  if (files.count > 0)
    [_delegate linkView:self gotFiles:files];

  return YES;
}

@end
