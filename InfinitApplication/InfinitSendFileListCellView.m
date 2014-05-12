//
//  InfinitSendFileListCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 24/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitSendFileListCellView.h"

@implementation InfinitSendFileListCellView
{
@private
  NSString* _file_path;
}

static NSDictionary* _filename_style = nil;
static NSDictionary* _file_size_style = nil;

//- Initialisation ---------------------------------------------------------------------------------

- (BOOL)isOpaque
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  // Grey background
  [IA_GREY_COLOUR(248.0) set];
  NSRectFill(self.bounds);

  // Dark grey line
  NSRect dark_grey_rect = NSMakeRect(self.bounds.origin.x,
                                     self.bounds.origin.y + 1.0,
                                     self.bounds.size.width,
                                     1.0);
  NSBezierPath* dark_grey_line = [NSBezierPath bezierPathWithRect:dark_grey_rect];
  [IA_GREY_COLOUR(235.0) set];
  [dark_grey_line fill];

  // White line
  NSRect white_rect = NSMakeRect(self.bounds.origin.x,
                                 self.bounds.origin.y,
                                 self.bounds.size.width,
                                 1.0);
  NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_rect];
  [IA_GREY_COLOUR(255.0) set];
  [white_line fill];
}

//- General Functions ------------------------------------------------------------------------------

- (NSUInteger)sizeForFolderAtPath:(NSString*)source
                            error:(NSError**)error
{
  NSArray* contents;
  unsigned long long size = 0;
  NSEnumerator* enumerator;
  NSString* path;
  BOOL is_directory;

  // Determine Paths to Add
  if ([[NSFileManager defaultManager] fileExistsAtPath:source isDirectory:&is_directory] && is_directory)
  {
    contents = [[NSFileManager defaultManager] subpathsAtPath:source];
  }
  else
  {
    contents = [NSArray array];
  }
  // Add Size Of All Paths
  enumerator = [contents objectEnumerator];
  while (path = [enumerator nextObject])
  {
    NSDictionary * fattrs = [[NSFileManager defaultManager]
                             attributesOfItemAtPath:[source stringByAppendingPathComponent:path]
                             error:error];
    size += [[fattrs objectForKey:NSFileSize] unsignedLongLongValue];
  }
  // Return Total Size in Bytes

  return size;
}

- (void)setupCellWithFilePath:(NSString*)file_path
{
  if (_filename_style == nil)
  {
    NSFont* file_name_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                        traits:NSUnboldFontMask
                                                                        weight:0
                                                                          size:12.0];
    NSMutableParagraphStyle* para_style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para_style.lineBreakMode = NSLineBreakByTruncatingMiddle;
    _filename_style = [IAFunctions textStyleWithFont:file_name_font
                                      paragraphStyle:para_style
                                              colour:IA_RGB_COLOUR(85.0, 158.0, 201.0)
                                              shadow:nil];
  }
  if (_file_size_style == nil)
  {
    NSFont* file_size_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                        traits:NSUnboldFontMask
                                                                        weight:0
                                                                          size:12.0];
    NSMutableParagraphStyle* paragraph_style = [[NSParagraphStyle defaultParagraphStyle]
                                                mutableCopy];
    paragraph_style.alignment = NSRightTextAlignment;
    _file_size_style = [IAFunctions textStyleWithFont:file_size_font
                                       paragraphStyle:paragraph_style
                                               colour:IA_RGB_COLOUR(202.0, 202.0, 202.0)
                                               shadow:nil];
  }

  _file_path = file_path;
  NSString* file_name = [NSString stringWithFormat:@"  %@", [file_path lastPathComponent]];
  self.file_icon_and_name.attributedTitle = [[NSAttributedString alloc]
                                             initWithString:file_name
                                             attributes:_filename_style];

  BOOL is_directory;
  NSNumber* file_size = 0;

  if ([[NSFileManager defaultManager] fileExistsAtPath:file_path isDirectory:&is_directory] && is_directory)
  {
    file_size = [NSNumber numberWithUnsignedInteger:[self sizeForFolderAtPath:file_path error:nil]];
  }
  else
  {
    NSDictionary* file_properties = [[NSFileManager defaultManager] attributesOfItemAtPath:file_path
                                                                                     error:NULL];
    file_size = [NSNumber numberWithUnsignedInteger:[file_properties fileSize]];
  }

  NSString* file_size_str = [IAFunctions fileSizeStringFrom:file_size];
  self.file_size.attributedStringValue = [[NSAttributedString alloc] initWithString:file_size_str
                                                                         attributes:_file_size_style];

  self.file_icon_and_name.image = [[NSWorkspace sharedWorkspace] iconForFile:file_path];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)filenameClicked:(NSButton*)sender
{
  if ([[NSFileManager defaultManager] fileExistsAtPath:_file_path])
  {
    NSArray* file_url = [NSArray arrayWithObject:[[NSURL fileURLWithPath:_file_path]
                                                  absoluteURL]];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:file_url];
  }
}

@end
