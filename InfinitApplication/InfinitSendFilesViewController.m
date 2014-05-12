//
//  InfinitSendFilesViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendFilesViewController.h"

#import "InfinitSendFileListCellView.h"

//- View -------------------------------------------------------------------------------------------

@interface InfinitSendFilesView : NSView
@property (nonatomic) IBOutlet InfinitSendFilesView* header_view;
@property (nonatomic) IBOutlet NSTableView* file_list;
@property (nonatomic, readwrite) BOOL open;
@end

@implementation InfinitSendFilesView

- (BOOL)isOpaque
{
  return YES;
}

- (NSSize)intrinsicContentSize
{
  CGFloat height = NSHeight(_header_view.frame);
  NSInteger no_rows = _file_list.numberOfRows;
  if (no_rows > 3)
    no_rows = 3;
  if (_open)
    height += (45.0 * no_rows);
  return NSMakeSize(317.0, height);
}

- (void)setOpen:(BOOL)open
{
  _open = open;
  self.header_view.open = open;
}

@end

//- Header View ------------------------------------------------------------------------------------

@implementation InfinitSendFilesHeaderView
{
@private
  NSTrackingArea* _tracking_area;
}

- (BOOL)isOpaque
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_GREY_COLOUR(248) set];
  NSRectFill(self.bounds);
  [IA_GREY_COLOUR(230) set];
  NSBezierPath* dark_line =
    [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, NSHeight(self.bounds) - 1.0,
                                                NSWidth(self.bounds), 1.0)];
  [dark_line fill];
  [IA_GREY_COLOUR(255) set];
  NSBezierPath* light_line =
    [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, NSHeight(self.bounds) - 2.0,
                                                NSWidth(self.bounds), 1.0)];
  [light_line fill];
  if (_open)
  {
    [IA_GREY_COLOUR(230) set];
    dark_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 1.0,
                                                            NSWidth(self.bounds), 1.0)];
    [dark_line fill];
    [IA_GREY_COLOUR(255) set];
    light_line =
      [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0,
                                                  NSWidth(self.bounds), 1.0)];
    [light_line fill];
  }
}

- (void)setOpen:(BOOL)open
{
  _open = open;
  if (_open)
    self.show_files.image = [IAFunctions imageNamed:@"send-icon-hide-files"];
  else
    self.show_files.image = [IAFunctions imageNamed:@"send-icon-show-files"];
}

- (void)setGot_files:(BOOL)got_files
{
  _got_files = got_files;
  if (!_got_files)
  {
    self.show_files.hidden = YES;
    return;
  }
  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
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

- (void)mouseExited:(NSEvent*)theEvent
{
  self.show_files.hidden = YES;
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  if (_got_files)
    self.show_files.hidden = NO;
}

@end

//- View Controller --------------------------------------------------------------------------------

@interface InfinitSendFilesViewController ()
@end

@implementation InfinitSendFilesViewController
{
@private
  id<InfinitSendFilesViewProtocol> _delegate;
  NSArray* _file_list;
  CGFloat _row_height;
  CGFloat _max_table_height;
  NSDictionary* _info_attrs;
}

- (id)initWithDelegate:(id<InfinitSendFilesViewProtocol>)delegate
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _row_height = 45.0;
    _max_table_height = _row_height * 3;
    NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                              traits:NSUnboldFontMask
                                                              weight:3
                                                                size:12.0];
    _info_attrs = [IAFunctions textStyleWithFont:font
                                  paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                          colour:IA_GREY_COLOUR(190)
                                          shadow:nil];
  }
  return self;
}

- (void)awakeFromNib
{
  [self updateWithFiles:_file_list];
}

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

- (NSNumber*)totalFileSize
{
  if (_file_list.count == 0)
    [NSNumber numberWithUnsignedInteger:0];

  NSNumber* res;

  for (NSString* file_path in _file_list)
  {
    BOOL is_directory;
    NSNumber* file_size;
    if ([[NSFileManager defaultManager] fileExistsAtPath:file_path isDirectory:&is_directory] && is_directory)
    {
      file_size = [NSNumber numberWithUnsignedInteger:[self sizeForFolderAtPath:file_path error:nil]];
    }
    else
    {
      NSDictionary* file_properties =
        [[NSFileManager defaultManager] attributesOfItemAtPath:file_path error:NULL];
      file_size = [NSNumber numberWithUnsignedInteger:[file_properties fileSize]];
    }
    res = [NSNumber numberWithUnsignedInteger:(res.unsignedIntegerValue + file_size.unsignedIntegerValue)];
  }
  return res;
}

- (void)updateWithFiles:(NSArray*)files
{
  _file_list = [files copy];
  NSString* info_str;
  if (_file_list.count == 0)
  {
    info_str = NSLocalizedString(@"  Add files...", nil);
    self.header_view.show_files.hidden = YES;
    [self hideFiles];
    self.header_view.open = NO;
    self.header_view.got_files = NO;
  }
  else if (_file_list.count == 1)
  {
    info_str = [NSString stringWithFormat:@"  1 %@ (%@)",
                NSLocalizedString(@"file", nil),
                [IAFunctions fileSizeStringFrom:[self totalFileSize]]];
    self.header_view.got_files = YES;
  }
  else
  {
    info_str = [NSString stringWithFormat:@"  %ld %@ (%@)",
                _file_list.count,
                NSLocalizedString(@"files", nil),
                [IAFunctions fileSizeStringFrom:[self totalFileSize]]];
    self.header_view.got_files = YES;
  }
  self.header_view.information.attributedTitle =
    [[NSAttributedString alloc] initWithString:info_str attributes:_info_attrs];
  if (_open)
    [self updateTable];
}

//- Table Handling ---------------------------------------------------------------------------------

- (CGFloat)tableHeight
{
  CGFloat height = self.table_view.numberOfRows * _row_height;
  if (height > _max_table_height)
    return _max_table_height;
  else
    return height;
}

- (void)updateTable
{
  CGFloat height = NSHeight(self.header_view.frame) + [self tableHeight];
  [_delegate fileList:self wantsChangeHeight:height];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
  return _file_list.count;
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
  return _row_height;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
  NSString* file = [_file_list objectAtIndex:row];
  if (file.length == 0)
    return nil;
  InfinitSendFileListCellView* cell = [tableView makeViewWithIdentifier:@"file_cell"
                                                                  owner:self];
  [cell setupCellWithFilePath:[_file_list objectAtIndex:row]];
  return cell;
}

//- User Interaction -------------------------------------------------------------------------------

- (IBAction)removeFileClicked:(NSButton*)sender
{
  NSInteger row = [self.table_view rowForView:sender];
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     [self.table_view beginUpdates];
     [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                            withAnimation:NSTableViewAnimationSlideRight];
     [self.table_view endUpdates];
   }
                      completionHandler:^
   {
     [_delegate fileList:self wantsRemoveFileAtIndex:row];
   }];
}

- (void)showFiles
{
  [self.table_view reloadData];
  _open = YES;
  ((InfinitSendFilesView*)self.view).open = _open;
  CGFloat height = NSHeight(self.header_view.frame) + [self tableHeight];
  [_delegate fileList:self wantsChangeHeight:height];
}

- (void)hideFiles
{
  if (!_open)
    return;
  _open = NO;
  ((InfinitSendFilesView*)self.view).open = _open;
  [_delegate fileList:self wantsChangeHeight:NSHeight(self.header_view.frame)];
}

- (IBAction)informationClicked:(NSButton*)sender
{
  if (_file_list.count == 0)
    [_delegate fileListGotAddFilesClicked:self];
  else if (_open)
    [self hideFiles];
  else
    [self showFiles];
}

- (IBAction)showFilesClicked:(NSButton*)sender
{
  if (_file_list.count == 0)
    return;
  if (_open)
    [self hideFiles];
  else
    [self showFiles];
}

- (IBAction)addFilesClicked:(NSButton*)sender
{
  [_delegate fileListGotAddFilesClicked:self];
}

@end
