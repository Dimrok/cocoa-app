//
//  InfinitSendFilesViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//- Header -----------------------------------------------------------------------------------------

@interface InfinitSendFilesHeaderView : NSView
@property (nonatomic, strong) IBOutlet NSButton* information;
@property (nonatomic, strong) IBOutlet NSButton* add_files;
@property (nonatomic, strong) IBOutlet NSButton* show_files;
@property (nonatomic, readwrite) BOOL open;
@end

//- Controller -------------------------------------------------------------------------------------

@protocol InfinitSendFilesViewProtocol;

@interface InfinitSendFilesViewController : NSViewController <NSTableViewDataSource,
                                                              NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet InfinitSendFilesHeaderView* header_view;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;
@property (nonatomic, readonly) BOOL open;


- (id)initWithDelegate:(id<InfinitSendFilesViewProtocol>)delegate;

- (void)updateWithFiles:(NSArray*)files;

- (void)showFiles;

@end

@protocol InfinitSendFilesViewProtocol <NSObject>

- (void)fileList:(InfinitSendFilesViewController*)sender
wantsRemoveFileAtIndex:(NSInteger)index;

- (void)fileList:(InfinitSendFilesViewController*)sender
wantsChangeHeight:(CGFloat)height;

- (void)fileListGotAddFilesClicked:(InfinitSendFilesViewController*)sender;

@end
