//
//  InfinitSettingsAvatarView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 22/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSettingsAvatarView.h"

@implementation InfinitSettingsAvatarView
{
@private
  BOOL _hover;
  NSRect _draw_rect;
  NSImage* _round_image;

  NSAttributedString* _drop_str;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize image = _image;

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
    _hover = NO;
    _uploading = NO;
    _draw_rect = NSMakeRect(self.bounds.origin.x + 1.0, self.bounds.origin.y + 1.0,
                            self.bounds.size.width - 2.0, self.bounds.size.height - 2.0);
    NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                              traits:NSUnboldFontMask
                                                              weight:5
                                                                size:12.0];
    NSDictionary* attrs = [IAFunctions textStyleWithFont:font
                                          paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                  colour:IA_GREY_COLOUR(132)
                                                  shadow:nil];
    _drop_str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Drop", nil)
                                                attributes:attrs];
    [self registerForDraggedTypes:@[NSFilenamesPboardType,NSTIFFPboardType]];
  }
  return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
  if (_hover)
  {
    NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:_draw_rect xRadius:7.0 yRadius:7.0];
    CGFloat pattern[2] = {3.0, 3.0};
    [path setLineDash:pattern count:2 phase:0.0];
    path.lineWidth = 2.0;
    [IA_GREY_COLOUR(132) set];
    [path stroke];
    NSPoint point = NSMakePoint(floor((self.bounds.size.width - _drop_str.size.width) / 2.0),
                                floor((self.bounds.size.height - _drop_str.size.height) / 2.0));
    [_drop_str drawAtPoint:point];
  }
  else
  {
    [_round_image drawInRect:_draw_rect
                    fromRect:NSZeroRect
                   operation:NSCompositeSourceOver
                    fraction:1.0];
    if (_uploading)
    {
      NSBezierPath* haze = [NSBezierPath bezierPathWithOvalInRect:_draw_rect];
      [IA_RGBA_COLOUR(255, 255, 255, 0.9) set];
      [haze fill];
    }
  }
}

//- Uploading ----------------------------------------------------------------------------------------

- (void)setUploading:(BOOL)uploading
{
  _hover = NO;
  _uploading = uploading;
  [self setNeedsDisplay:YES];
}

//- Image Handling ---------------------------------------------------------------------------------

- (NSImage*)squareCrop:(NSImage*)image
{
  CGFloat width = fmin(image.size.width, image.size.height);
  NSImage* res = [[NSImage alloc] initWithSize:NSMakeSize(width, width)];
  NSRect dest_rect = NSMakeRect(0.0, 0.0, width, width);
  NSRect source_rect = NSMakeRect(floor((image.size.width - width) / 2.0),
                                  floor((image.size.height - width) / 2.0), width, width);
  [res lockFocus];
  [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
  [image drawInRect:dest_rect fromRect:source_rect operation:NSCompositeCopy fraction:1.0];
  [res unlockFocus];
  return res;
}

- (void)setImage:(NSImage*)image
{
  _image = [self squareCrop:image];
  _round_image = [IAFunctions makeRoundAvatar:_image.copy
                                   ofDiameter:self.bounds.size.width
                        withBorderOfThickness:2.0 inColour:IA_GREY_COLOUR(255)
                            andShadowOfRadius:1.0];
  [self setNeedsDisplay:YES];
}

- (NSImage*)image
{
  return _image;
}

//- Handle Drag and Drop ---------------------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
  if (_uploading)
    return NSDragOperationNone;
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if ([paste_board availableTypeFromArray:@[NSFilenamesPboardType]])
  {
    NSString* file = [paste_board propertyListForType:NSFilenamesPboardType][0];
    CFStringRef file_ext = (__bridge CFStringRef)file.pathExtension;
    CFStringRef file_uti =
      UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, file_ext, NULL);
    if (UTTypeConformsTo(file_uti, kUTTypeImage))
    {
      _hover = YES;
      [self setNeedsDisplay:YES];
      CFRelease(file_uti);
      return NSDragOperationCopy;
    }
  }
  else if ([paste_board availableTypeFromArray:@[NSTIFFPboardType]])
  {
    _hover = YES;
    [self setNeedsDisplay:YES];
    return NSDragOperationCopy;
  }
  return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
  _hover = NO;
  [self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
  if (_uploading)
    return NO;
  _hover = NO;
  [self setNeedsDisplay:YES];
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if ([paste_board availableTypeFromArray:@[NSFilenamesPboardType]])
  {
    NSString* file = [paste_board propertyListForType:NSFilenamesPboardType][0];
    CFStringRef file_ext = (__bridge CFStringRef)file.pathExtension;
    CFStringRef file_uti =
    UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, file_ext, NULL);
    if (UTTypeConformsTo(file_uti, kUTTypeImage))
    {
      CFRelease(file_uti);
      NSDictionary* file_properties = [[NSFileManager defaultManager] attributesOfItemAtPath:file
                                                                                       error:NULL];
      NSImage* image = [[NSImage alloc] initWithContentsOfFile:file];
      if (image != nil)
      {
        [_delegate settingsAvatarGotImage:self.image ofSize:file_properties.fileSize];
        if (file_properties.fileSize <= [_delegate maxAvatarSize])
        {
          self.image = image;
          return YES;
        }
        else
        {
          return NO;
        }
      }
    }
  }
  else if ([paste_board availableTypeFromArray:@[NSTIFFPboardType]])
  {
    NSImage* image = [paste_board readObjectsForClasses:@[NSImage.class] options:@{}][0];
    NSData* image_data = [[image representations][0] representationUsingType:NSPNGFileType
                                                                  properties:nil];
    image = [[NSImage alloc] initWithData:image_data];
    if (image != nil)
    {
      [_delegate settingsAvatarGotImage:self.image ofSize:image_data.length];
      if (image_data.length <= [_delegate maxAvatarSize])
      {
        self.image = image;
        return YES;
      }
      else
      {
        return NO;
      }
    }
  }
  return NO;
}

@end
