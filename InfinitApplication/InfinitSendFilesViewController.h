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

@protocol InfinitSendFilesSubViewProtocol;

@interface InfinitSendFilesView : NSView
@property (assign, readwrite) id<InfinitSendFilesSubViewProtocol> delegate;
@property (nonatomic, readwrite) NSUInteger rows;
@property (nonatomic, readwrite) CGFloat hover;
@end

@protocol InfinitSendFilesSubViewProtocol <NSObject>
- (void)sendFilesViewWantsAddFiles:(InfinitSendFilesView*)sender;
- (void)sendFilesView:(InfinitSendFilesView*)sender
      gotFilesDropped:(NSArray*)files;
@end

//- Controller -------------------------------------------------------------------------------------

@protocol InfinitSendFilesViewProtocol;

@interface InfinitSendFilesViewController : NSViewController <InfinitSendFilesSubViewProtocol>

@property (nonatomic, weak) IBOutlet InfinitSendFilesCollectionView* collection_view;
@property (nonatomic, readonly) NSUInteger file_size;
@property (nonatomic, weak) IBOutlet NSTextField* info;
@property (nonatomic, strong) IBOutlet InfinitSendFilesView* view;

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
- (void)fileList:(InfinitSendFilesViewController*)sender
 gotFilesDropped:(NSArray*)files;

@end
