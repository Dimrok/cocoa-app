//
//  InfinitSendFileListCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 24/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "OldInfinitSendFileListCellView.h"

@implementation OldInfinitSendFileListCellView
{
@private
  NSString* _file_path;
  NSOperationQueue* _operation_queue;
  NSUInteger _calcd_file_size;
}

static NSDictionary* _filename_style = nil;
static NSDictionary* _file_size_style = nil;

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _file_size = 0;
    _operation_queue = [[NSOperationQueue alloc] init];
    _operation_queue.maxConcurrentOperationCount = 1;
  }
  return self;
}

- (void)dealloc
{
  if (_operation_queue.operationCount > 0)
    [_operation_queue cancelAllOperations];
}

- (void)prepareForReuse
{
  _calcd_file_size = 0;
  if (_operation_queue.operationCount > 0)
    [_operation_queue cancelAllOperations];
}

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

- (NSBlockOperation*)asynchronouslySetFileSize:(NSString*)file_path
{
  NSBlockOperation* block = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation* weak_block = block;
  __weak NSString* weak_file_path = file_path;
  __unsafe_unretained OldInfinitSendFileListCellView* weak_self = self;
  [block addExecutionBlock:^{
    BOOL is_directory;
    NSUInteger res = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:weak_file_path isDirectory:&is_directory] && is_directory)
    {
      NSURL* file_url =
      [NSURL URLWithString:[weak_file_path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
      if (file_url != nil)
      {
        NSDirectoryEnumerator* dir_enum =
        [[NSFileManager defaultManager] enumeratorAtURL:file_url
                             includingPropertiesForKeys:@[NSURLTotalFileAllocatedSizeKey,
                                                          NSURLIsDirectoryKey]
                                                options:NSDirectoryEnumerationSkipsHiddenFiles
                                           errorHandler:nil];
        for (NSURL* file in dir_enum)
        {
          if (weak_block.isCancelled)
            return;
          @autoreleasepool
          {
            NSNumber* is_directory;
            [file getResourceValue:&is_directory forKey:NSURLIsDirectoryKey error:NULL];
            if (is_directory.boolValue == NO)
            {
              NSNumber* file_size;
              [file getResourceValue:&file_size forKey:NSURLFileSizeKey error:NULL];
              res += file_size.unsignedIntegerValue;
            }
          }
        }
      }
    }
    else
    {
      NSDictionary* file_properties =
        [[NSFileManager defaultManager] attributesOfItemAtPath:weak_file_path error:NULL];
      res = [file_properties fileSize];
    }

    NSNumber* file_size = [NSNumber numberWithUnsignedInteger:res];
    __weak NSNumber* weak_file_size = file_size;

    // Ensure that the drawing takes place on the main thread.
    if ([weak_self respondsToSelector:@selector(updateFileSize:)])
    {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [weak_self updateFileSize:weak_file_size];
      }];
    }
  }];
  return block;
}

- (void)updateFileSize:(NSNumber*)file_size
{
  _calcd_file_size = file_size.unsignedIntegerValue;
  NSString* file_size_str =
    [IAFunctions fileSizeStringFrom:[NSNumber numberWithUnsignedInteger:_calcd_file_size]];
  self.file_size.attributedStringValue =
    [[NSAttributedString alloc] initWithString:file_size_str attributes:_file_size_style];
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

  self.file_size.attributedStringValue = [[NSAttributedString alloc] initWithString:@""
                                                                         attributes:_file_size_style];

  if (_calcd_file_size == 0)
  {
    [_operation_queue addOperation:[self asynchronouslySetFileSize:file_path]];
  }
  else
  {
    NSString* file_size_str =
    [IAFunctions fileSizeStringFrom:[NSNumber numberWithUnsignedInteger:_calcd_file_size]];
    self.file_size.attributedStringValue =
      [[NSAttributedString alloc] initWithString:file_size_str attributes:_file_size_style];
  }

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
