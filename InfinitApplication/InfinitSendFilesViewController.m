//
//  InfinitSendFilesViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendFilesViewController.h"

#import "InfinitMetricsManager.h"
#import "InfinitSendFileView.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitDataSize.h>

#import <QuickLook/QuickLook.h>
#import <QuartzCore/QuartzCore.h>

//- File Model -------------------------------------------------------------------------------------

@implementation InfinitSendFileModel
{
@private
  NSImage* _preview;
}

- (id)initWithPath:(NSString*)path
{
  if (self = [super init])
  {
    _add_files_placeholder = NO;
    _preview = nil;
    _path = path;
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (NSImage*)icon
{
  if (self.add_files_placeholder)
    return [IAFunctions imageNamed:@"send-icon-add-file"];
  if (_preview != nil)
    return _preview;
  BOOL is_dir;
  [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&is_dir];
  if (!is_dir)
    [self performSelectorInBackground:@selector(getFilePreview) withObject:nil];
  return [[NSWorkspace sharedWorkspace] iconForFile:self.path];
}

- (void)getFilePreview
{
  NSURL* path_url = [NSURL fileURLWithPath:self.path];
  NSDictionary* options = @{(NSString*)kQLThumbnailOptionIconModeKey: [NSNumber numberWithBool:YES]};
  CGImageRef ref = QLThumbnailImageCreate(kCFAllocatorDefault,
                                          (__bridge CFURLRef)path_url,
                                          CGSizeMake(110, 110),
                                          (__bridge CFDictionaryRef)options);
  NSImage* res = [[NSImage alloc] initWithCGImage:ref size:NSMakeSize(200, 200)];
  if (ref)
  {
    CFRelease(ref);
    [self willChangeValueForKey:@"icon"];
    _preview = res;
    [self didChangeValueForKey:@"icon"];
  }
}

- (NSString*)name
{
  if (self.add_files_placeholder)
    return NSLocalizedString(@"Add files...", nil);
  return self.path.lastPathComponent;
}

- (id)initAddFilesPlaceholder
{
  if (self = [super init])
  {
    _add_files_placeholder = YES;
    _path = nil;
  }
  return self;
}

@end

//- Send Files Collection View Item ----------------------------------------------------------------

@implementation InfinitSendFilesCollectionViewItem

// Override copyWithZone: so that we can attach the close button to the view.
- (id)copyWithZone:(NSZone*)zone
{
  InfinitSendFilesCollectionViewItem* res = [super copyWithZone:zone];
  InfinitSendFileView* view = (InfinitSendFileView*)res.view;
  view.remove_button = [view viewWithTag:5];
  view.icon_button = [view viewWithTag:6];
  return res;
}

@end

//- Send Files Collection View ---------------------------------------------------------------------

@implementation InfinitSendFilesCollectionView

- (NSCollectionViewItem*)newItemForRepresentedObject:(id)object
{
  InfinitSendFilesCollectionViewItem* res =
    (InfinitSendFilesCollectionViewItem*)[super newItemForRepresentedObject:object];
  InfinitSendFileView* view = (InfinitSendFileView*)res.view;
  if ([object path] == nil)
    view.add_files_placeholder = YES;
  else
    view.add_files_placeholder = NO;
  return res;
}

@end

//- View -------------------------------------------------------------------------------------------

@implementation InfinitSendFilesView
{
@private
  NSArray* _icons;
  NSTrackingArea* _tracking_area;
  NSMutableAttributedString* _drop_str;
  NSMutableAttributedString* _click_str;
  NSArray* _drag_types;
}

static CGFloat _radius = 150.0;

- (BOOL)isOpaque
{
  return YES;
}

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
    _icons = @[[IAFunctions imageNamed:@"send-icon-media-picture"],
               [IAFunctions imageNamed:@"send-icon-media-folder"],
               [IAFunctions imageNamed:@"send-icon-media-ps"],
               [IAFunctions imageNamed:@"send-icon-media-video"]];

    NSFont* drop_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Montserrat"
                                                                   traits:NSUnboldFontMask
                                                                   weight:15
                                                                     size:12.0];
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSCenterTextAlignment;
    NSDictionary* drop_attrs = [IAFunctions textStyleWithFont:drop_font
                                               paragraphStyle:para
                                                       colour:[InfinitColor colorWithRed:81 green:81 blue:73]
                                                       shadow:nil];
    _drop_str =
      [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"DROP FILES HERE", nil)
                                             attributes:drop_attrs];
    NSFont* click_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                    traits:NSUnboldFontMask
                                                                    weight:3
                                                                      size:12.0];
    NSDictionary* click_attrs = [IAFunctions textStyleWithFont:click_font
                                                paragraphStyle:para
                                                        colour:IA_GREY_COLOUR(164)
                                                        shadow:nil];
    _click_str =
      [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"or click to add files...", nil)
                                             attributes:click_attrs];
    _drag_types = @[NSFilenamesPboardType];
    [self registerForDraggedTypes:_drag_types];
  }
  return self;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if ([paste_board availableTypeFromArray:_drag_types])
  {
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
    [_delegate sendFilesView:self gotFilesDropped:files];

  return YES;
}

- (void)setHover:(CGFloat)hover
{
  _hover = hover;
  [self setNeedsDisplay:YES];
}

- (CGFloat)rotationOfImage:(NSUInteger)i
                  forHover:(CGFloat)hover
{
  CGFloat hover_delta = 15.0;
  if (i < 2)
    hover_delta = (hover * hover_delta);
  else
    hover_delta = -(hover * hover_delta);
  CGFloat angle;
  switch (i)
  {
    case 0:
      angle = 20.0;
      break;
    case 1:
      angle = 7.5;
      break;
    case 2:
      angle = -7.5;
      break;
    case 3:
      angle = -20.0;
      break;

    default:
      angle = 0.0;
      break;
  }
  return angle + hover_delta;
}

- (CGFloat)degToRad:(CGFloat)deg
{
  return deg * (M_PI / 180.0);
}

- (NSPoint)locationOfImage:(NSUInteger)i
                  forHover:(CGFloat)hover
{
  CGFloat angle = 90.0;
  CGFloat angle_delta = 15.0;
  CGFloat hover_delta = 10.0;
  CGFloat multiplier = 0.0;
  switch (i)
  {
    case 0:
      multiplier = +2.0;
      break;
    case 1:
      multiplier = +0.65;
      break;
    case 2:
      multiplier = -0.65;
      break;
    case 3:
      multiplier = -2.0;
      break;
    default:
      break;
  }
  angle = angle + (angle_delta * multiplier);
  if (i < 2)
    angle = angle + (hover_delta * hover);
  else
    angle = angle - (hover_delta * hover);
  return NSMakePoint(_radius * cos([self degToRad:angle]), _radius * sin([self degToRad:angle]));
}

- (void)drawRect:(NSRect)dirtyRect
{
  [[InfinitColor colorWithGray:248] set];
  NSRectFill(self.bounds);
  [[InfinitColor colorWithGray:224] set];
  NSRectFill(NSMakeRect(0.0f, self.bounds.size.height - 1.0f, self.bounds.size.width, 1.0f));
  if (self.rows == 0)
  {
    CGFloat border = 15.0;
    NSBezierPath* path =
      [NSBezierPath bezierPathWithRect:NSMakeRect(border,
                                                  border,
                                                  NSWidth(self.bounds) - (2 * border),
                                                  NSHeight(self.bounds) - (2 * border))];
    CGFloat pattern[2] = {10.0, 5.0};
    [path setLineDash:pattern count:2 phase:0.0];
    path.lineWidth = 1.0;
    [[InfinitColor colorWithGray:215] set];
    [path stroke];
    CGFloat bg_diff = (255 - 248) * _hover;
    [IA_RGB_COLOUR(248 + bg_diff, 248 + bg_diff, 248 + bg_diff) set];
    NSRectFill(NSMakeRect(border + 1.0,
                          border + 1.0,
                          NSWidth(self.bounds) - (2 * border) - 2.0,
                          NSHeight(self.bounds) - (2 * border) - 2.0));
    [_drop_str drawAtPoint:NSMakePoint((NSWidth(self.bounds) - _drop_str.size.width) / 2.0, 65.0)];
    [_click_str drawAtPoint:NSMakePoint((NSWidth(self.bounds) - _click_str.size.width) / 2.0, 45.0)];
    for (NSUInteger i = 0; i < _icons.count; i++)
    {
      NSImage* image = _icons[i];
      NSPoint loc = [self locationOfImage:i forHover:_hover];
      CGFloat rot_angle = [self rotationOfImage:i forHover:_hover];
      CGFloat x_diff = 0.0;
      CGFloat y_diff = 0.0;
      if (i < 2)
        x_diff = (image.size.height * sin([self degToRad:rot_angle]) / 2.0);
      else
        y_diff = image.size.width * sin([self degToRad:rot_angle]);
      NSAffineTransform* image_rotation = [NSAffineTransform transform];
      [image_rotation translateXBy:floor((loc.x + (NSWidth(self.bounds) / 2.0) - (image.size.width / 2.0)) + x_diff)
                               yBy:floor(loc.y - (image.size.height / 2.0) - 25.0 - y_diff)];
      [image_rotation rotateByDegrees:rot_angle];
      [image_rotation concat];

      [NSGraphicsContext saveGraphicsState];
      [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

      [image drawAtPoint:NSMakePoint(0.0, 0.0)
                fromRect:NSZeroRect
               operation:NSCompositeSourceOver
                fraction:1.0];

      [NSGraphicsContext restoreGraphicsState];

      [image_rotation invert];
      [image_rotation concat];
    }
  }
}

- (NSSize)intrinsicContentSize
{
  if (self.rows == 0)
    return NSMakeSize(317.0, 197.0);

  CGFloat height = self.rows * 88.0 + 45.0;
  return NSMakeSize(317.0, height);
}

- (void)mouseDown:(NSEvent*)theEvent
{
  if (theEvent.clickCount == 1 && self.rows == 0)
  {
    [_delegate sendFilesViewWantsAddFiles:self];
  }
}

- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];

  [self addTrackingArea:_tracking_area];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     [self.animator setHover:1.0];
   } completionHandler:^{
     self.hover = 1.0;
   }];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     [self.animator setHover:0.0];
   } completionHandler:^{
     self.hover = 0.0;
   }];
}

- (void)resetCursorRects
{
  [super resetCursorRects];
  if (self.rows == 0)
  {
    NSCursor* cursor = [NSCursor pointingHandCursor];
    [self addCursorRect:self.bounds cursor:cursor];
  }
}

+ (id)defaultAnimationForKey:(NSString*)key
{
  if ([key isEqualToString:@"hover"])
    return [CABasicAnimation animation];

  return [super defaultAnimationForKey:key];
}

@end

//- View Controller --------------------------------------------------------------------------------

@interface InfinitSendFilesViewController ()
@end

@implementation InfinitSendFilesViewController
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitSendFilesViewProtocol> _delegate;
  CGFloat _row_height;
  CGFloat _max_table_height;
  NSOperationQueue* _operation_queue;
}

static NSDictionary* _info_attrs = nil;

- (id)initWithDelegate:(id<InfinitSendFilesViewProtocol>)delegate
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _row_height = 45.0;
    _max_table_height = _row_height * 3;
    if (_info_attrs == nil)
    {
      NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                traits:NSUnboldFontMask
                                                                weight:3
                                                                  size:11.0];
      NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
      para.alignment = NSRightTextAlignment;
      _info_attrs = [IAFunctions textStyleWithFont:font
                                    paragraphStyle:para
                                            colour:IA_GREY_COLOUR(190)
                                            shadow:nil];
    }
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

- (void)awakeFromNib
{
  // WORKAROUND: Stop 15" Macbook Pro always rendering scroll bars
  // http://www.cocoabuilder.com/archive/cocoa/317591-can-hide-scrollbar-on-nstableview.html
  [self.collection_view.enclosingScrollView setScrollerStyle:NSScrollerStyleOverlay];
  [self.collection_view.enclosingScrollView.verticalScroller setControlSize:NSSmallControlSize];
  self.view.rows = 0;
  self.info.hidden = YES;
}

- (void)loadView
{
  [super loadView];
  self.view.delegate = self;
}

- (void)stopCalculatingFileSize
{
  if (_operation_queue.operationCount > 0)
    [_operation_queue cancelAllOperations];
}

- (void)filesChanged
{
  if (_file_list.count > 1)
  {
    NSString* calculating = NSLocalizedString(@"Calculating size...", nil);
    self.info.attributedStringValue = [[NSAttributedString alloc] initWithString:calculating
                                                                      attributes:_info_attrs];
    __unsafe_unretained InfinitSendFilesViewController* weak_self = self;
    [_operation_queue addOperation:[weak_self asynchronouslySetFileSize]];
  }
  if (_file_list.count == 1)
  {
    self.view.rows = 0;
    self.collection_view.enclosingScrollView.hidden = YES;
    self.info.hidden = YES;
  }
  else if (_file_list.count < 4)
  {
    self.view.rows = 1;
    self.collection_view.enclosingScrollView.hidden = NO;
    self.info.hidden = NO;
  }
  else
  {
    self.view.rows = 2;
    self.collection_view.enclosingScrollView.hidden = NO;
    self.info.hidden = NO;
  }
  [_delegate fileList:self wantsChangeHeight:self.view.intrinsicContentSize.height];
}

- (NSOperation*)asynchronouslySetFileSize
{
  NSBlockOperation* block = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation* weak_block = block;
  __unsafe_unretained InfinitSendFilesViewController* weak_self = self;
  __weak NSArray* weak_file_list = _file_list;
  [block addExecutionBlock:^{
    if (weak_file_list.count == 1)
      return;

    NSUInteger res = 0;

    @autoreleasepool
    {
      for (InfinitSendFileModel* file in weak_file_list)
      {
        if (weak_block.isCancelled)
          return;

        BOOL is_directory;
        NSUInteger file_size = 0;
        if ([[NSFileManager defaultManager] fileExistsAtPath:file.path isDirectory:&is_directory] && is_directory)
        {
          NSURL* file_url =
            [NSURL URLWithString:[file.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
            [[NSFileManager defaultManager] attributesOfItemAtPath:file.path error:NULL];
          file_size = [file_properties fileSize];
        }
        res += file_size;
      }

      NSNumber* total_size = [NSNumber numberWithUnsignedInteger:res];

      NSString* info_str;
      if (weak_file_list.count == 1)
      {
        info_str = [NSString stringWithFormat:@"1 %@ (%@)",
                    NSLocalizedString(@"file", nil),
                    [InfinitDataSize fileSizeStringFrom:total_size]];
      }
      else
      {
        info_str = [NSString stringWithFormat:@"%ld %@ (%@)",
                    weak_file_list.count - 1,
                    NSLocalizedString(@"files", nil),
                    [InfinitDataSize fileSizeStringFrom:total_size]];
      }
      if (weak_self != nil)
      {
        weak_self.info.attributedStringValue =
          [[NSAttributedString alloc] initWithString:info_str attributes:_info_attrs];
      }
    }
  }];
  return block;
}

- (void)updateWithFiles:(NSArray*)files
{
  if (_operation_queue.operationCount > 0)
    [_operation_queue cancelAllOperations];

  NSMutableArray* temp_arr = [NSMutableArray array];
  for (NSString* path in files)
    [temp_arr addObject:[[InfinitSendFileModel alloc] initWithPath:[path copy]]];
  [temp_arr addObject:[[InfinitSendFileModel alloc] initAddFilesPlaceholder]];
  [self setFile_list:temp_arr];
}

//- User Interaction -------------------------------------------------------------------------------

- (void)removeFileClicked:(NSString*)file
{
  NSUInteger index = 0;
  for (InfinitSendFileModel* model in _file_list)
  {
    if ([model.path isEqualToString:file])
      break;
    index++;
  }
  if (index < _file_list.count)
    [self removeObjectFromFile_listAtIndex:index];
}

- (void)fileIconClicked:(InfinitSendFileModel*)file
{
  if (file.add_files_placeholder)
    [_delegate fileListGotAddFilesClicked:self];
}

//- KVO Array --------------------------------------------------------------------------------------

- (void)insertObject:(InfinitSendFileModel*)object
  inFile_listAtIndex:(NSUInteger)index
{
  [_file_list insertObject:object atIndex:index];
  [self filesChanged];
}

- (void)removeObjectFromFile_listAtIndex:(NSUInteger)index
{
  [_file_list removeObjectAtIndex:index];
  [_delegate fileList:self wantsRemoveFileAtIndex:index];
  [self filesChanged];
}

- (void)setFile_list:(NSMutableArray*)file_list
{
  _file_list = file_list;
  [self filesChanged];
}

//- Subview Protocol -------------------------------------------------------------------------------

- (void)sendFilesViewWantsAddFiles:(InfinitSendFilesView*)sender
{
  [_delegate fileListGotAddFilesClicked:self];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_ADD_FILES];
}

- (void)sendFilesView:(InfinitSendFilesView*)sender
      gotFilesDropped:(NSArray*)files
{
  [_delegate fileList:self gotFilesDropped:files];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_ADD_FILES];
}

@end
