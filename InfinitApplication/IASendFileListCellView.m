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
    
    NSDictionary* file_properties = [NSFileManager.defaultManager attributesOfItemAtPath:file_path
                                                                                     error:NULL];
    // XXX Folder size doesn't work, need to go inside and calculate
    NSUInteger file_size = [file_properties fileSize];
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
