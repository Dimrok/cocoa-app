//
//  IAHoverButtonCell.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/5/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IAHoverButtonCell : NSButtonCell
{
@private
    NSImage* _normal_image;
    NSImage* _hover_image;
}

@property (nonatomic, strong) NSImage* hoverImage;

- (void)setHoverImage:(NSImage*)hoverImage;

@end
