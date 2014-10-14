//
//  InfinitSendFilesViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//- File Model -------------------------------------------------------------------------------------

@interface InfinitSendFileModel : NSObject
@property (nonatomic, readonly) BOOL add_files_placeholder;
@property (nonatomic, readwrite) NSImage* icon;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readwrite) NSString* path;

- (id)initAddFilesPlaceholder;

@end

//- Send Files Collection View Item ----------------------------------------------------------------

@interface InfinitSendFilesCollectionViewItem : NSCollectionViewItem
@end

//- Send Files Collection View ---------------------------------------------------------------------

@interface InfinitSendFilesCollectionView : NSCollectionView
@end

//- Send Files View --------------------------------------------------------------------------------

@interface InfinitSendFilesView : NSView
@property (nonatomic, readwrite) NSUInteger rows;
@property (nonatomic, readwrite) CGFloat hover;
@end

//- Controller -------------------------------------------------------------------------------------

@protocol InfinitSendFilesViewProtocol;

@interface InfinitSendFilesViewController : NSViewController

@property (nonatomic, weak) IBOutlet InfinitSendFilesCollectionView* collection_view;
@property (nonatomic, weak) IBOutlet NSTextField* info;
@property (nonatomic, weak) IBOutlet InfinitSendFilesView* view;

@property (nonatomic, readwrite) NSMutableArray* file_list;
@property (nonatomic, readonly) BOOL open;


- (id)initWithDelegate:(id<InfinitSendFilesViewProtocol>)delegate;

- (void)updateWithFiles:(NSArray*)files;

- (void)stopCalculatingFileSize;

@end

@protocol InfinitSendFilesViewProtocol <NSObject>

- (void)fileList:(InfinitSendFilesViewController*)sender
wantsRemoveFileAtIndex:(NSInteger)index;

- (void)fileList:(InfinitSendFilesViewController*)sender
wantsChangeHeight:(CGFloat)height;

- (void)fileListGotAddFilesClicked:(InfinitSendFilesViewController*)sender;

@end
