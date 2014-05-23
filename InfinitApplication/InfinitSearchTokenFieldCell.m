//
//  InfinitSearchTokenFieldCell.m
//  InfinitApplication
//
//  Created by Christopher Crone on 22/04/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSearchTokenFieldCell.h"

@implementation InfinitSearchTokenFieldCell

- (void)awakeFromNib
{
  _cFlags.vCentered = 1;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame
                       inView:(NSView*)controlView
{
  [IA_GREY_COLOUR(255) set];
  NSRectFill(cellFrame);
  [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
