//
//  InfinitSendFilesViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//- Header -----------------------------------------------------------------------------------------

@interface OldInfinitSendFilesHeaderView : NSView
@property (nonatomic, weak) IBOutlet NSButton* information;
@property (nonatomic, weak) IBOutlet NSButton* add_files;
@property (nonatomic, weak) IBOutlet NSButton* show_files;
@property (nonatomic, readwrite) BOOL open;
@property (nonatomic, readwrite) BOOL got_files;
@end

//- Controller -------------------------------------------------------------------------------------

@protocol OldInfinitSendFilesViewProtocol;

@interface OldInfinitSendFilesViewController : NSViewController <NSTableViewDataSource,
                                                                 NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet OldInfinitSendFilesHeaderView* header_view;
@property (nonatomic, weak) IBOutlet NSTableView* table_view;
@property (nonatomic, readonly) BOOL open;


- (id)initWithDelegate:(id<OldInfinitSendFilesViewProtocol>)delegate;

- (void)updateWithFiles:(NSArray*)files;

- (void)showFiles;

- (void)stopCalculatingFileSize;

@end

@protocol OldInfinitSendFilesViewProtocol <NSObject>

- (void)fileList:(OldInfinitSendFilesViewController*)sender
wantsRemoveFileAtIndex:(NSInteger)index;

- (void)fileList:(OldInfinitSendFilesViewController*)sender
wantsChangeHeight:(CGFloat)height;

- (void)fileListGotAddFilesClicked:(OldInfinitSendFilesViewController*)sender;

@end
