//
//  IASendFileListCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/5/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASendFileListCellView.h"

@implementation IASendFileListCellView

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        // Initialization code here.
    }
    
    return self;
}

- (NSString*)description
{
    return @"[SendFileListCellView]";
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Grey backgrounds
    NSRect grey_rect = NSMakeRect(self.bounds.origin.x,
                                  self.bounds.origin.y + 2.0,
                                  self.bounds.size.width,
                                  self.bounds.size.height - 2.0);
    NSBezierPath* grey_path = [NSBezierPath bezierPathWithRect:grey_rect];
    [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
    [grey_path fill];
    
    // White line
    NSRect white_rect = NSMakeRect(self.bounds.origin.x,
                                   self.bounds.origin.y + 1.0,
                                   self.bounds.size.width,
                                   1.0);
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_rect];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_line fill];
    
    // Dark grey line
    NSRect dark_grey_rect = NSMakeRect(self.bounds.origin.x,
                                       self.bounds.origin.y,
                                       self.bounds.size.width,
                                       1.0);
    NSBezierPath* dark_grey_line = [NSBezierPath bezierPathWithRect:dark_grey_rect];
    [TH_RGBCOLOR(220.0, 220.0, 220.0) set];
    [dark_grey_line fill];
}

//- General Functions ------------------------------------------------------------------------------

- (void)setupCellWithFilePath:(NSString*)file_path
{
    NSString* file_name = [file_path lastPathComponent];
    NSDictionary* file_name_style = [IAFunctions
                                        textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                           paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                   colour:TH_RGBCOLOR(85.0, 158.0, 201.0)
                                                   shadow:nil];
    self.file_name.attributedStringValue = [[NSAttributedString alloc]
                                                initWithString:file_name
                                                    attributes:file_name_style];
    
    NSDictionary* file_properties = [[NSFileManager defaultManager]
                                            attributesOfFileSystemForPath:file_path
                                                                    error:nil];
    NSNumber* file_size = [file_properties objectForKey:NSFileSize];
    NSString* file_size_str = [IAFunctions fileSizeStringFrom:file_size];
    NSMutableParagraphStyle* paragraph_style = [[NSParagraphStyle defaultParagraphStyle]
                                                mutableCopy];
    paragraph_style.alignment = NSRightTextAlignment;
    NSDictionary* style = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                          paragraphStyle:paragraph_style
                                                  colour:TH_RGBCOLOR(202.0, 202.0, 202.0)
                                                  shadow:nil];
    self.file_name.attributedStringValue = [[NSAttributedString alloc] initWithString:file_size_str
                                                                           attributes:style];
    
    self.file_type_image.image = [[NSWorkspace sharedWorkspace] iconForFile:file_path];
}

@end
