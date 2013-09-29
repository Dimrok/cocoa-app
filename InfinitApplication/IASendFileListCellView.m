//
//  IASendFileListCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/5/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASendFileListCellView.h"

@implementation IASendFileListCellView
{
@private
    NSString* _file_path;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        // Initialization code here.
    }
    
    return self;
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
    _file_path = file_path;
    NSString* file_name = [file_path lastPathComponent];
    NSDictionary* file_name_style = [IAFunctions
                                        textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                           paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                   colour:IA_RGB_COLOUR(85.0, 158.0, 201.0)
                                                   shadow:nil];
    self.file_icon_and_name.attributedTitle = [[NSAttributedString alloc]
                                               initWithString:file_name
                                                   attributes:file_name_style];
    
    BOOL is_directory;
    NSUInteger file_size = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:file_path isDirectory:&is_directory] && is_directory)
    {
        file_size = [self sizeForFolderAtPath:file_path error:nil];
    }
    else
    {
        NSDictionary* file_properties = [[NSFileManager defaultManager] attributesOfItemAtPath:file_path
                                                                                         error:NULL];
        file_size = [file_properties fileSize];
    }
    NSString* file_size_str = [IAFunctions fileSizeStringFrom:file_size];
    NSMutableParagraphStyle* paragraph_style = [[NSParagraphStyle defaultParagraphStyle]
                                                mutableCopy];
    paragraph_style.alignment = NSRightTextAlignment;
    NSDictionary* style = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                          paragraphStyle:paragraph_style
                                                  colour:IA_RGB_COLOUR(202.0, 202.0, 202.0)
                                                  shadow:nil];
    self.file_size.attributedStringValue = [[NSAttributedString alloc] initWithString:file_size_str
                                                                           attributes:style];
    
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
