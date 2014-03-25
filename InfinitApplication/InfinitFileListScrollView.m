//
//  InfinitFileListScrollView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 24/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitFileListScrollView.h"

@implementation InfinitFileListScrollView

-(void)scrollWheel:(NSEvent*)theEvent {

  [[self nextResponder] scrollWheel:theEvent];
}

@end
