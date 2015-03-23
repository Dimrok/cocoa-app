//
//  InfinitSearchRowModel.h
//  InfinitApplication
//
//  Created by Christopher Crone on 22/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "InfinitSearchPersonResult.h"

@interface InfinitSearchRowModel : NSObject

@property (nonatomic, readonly) NSImage* avatar;
@property (nonatomic, readonly) id destination;
@property (nonatomic, readonly) NSString* fullname;
@property (nonatomic, readwrite) BOOL hover;
@property (nonatomic, readwrite) BOOL selected;
@property (nonatomic, readonly) InfinitUser* user;

+ (instancetype)rowModelWithSearchPersonResult:(InfinitSearchPersonResult*)person;

+ (instancetype)rowModelWithSearchPersonResult:(InfinitSearchPersonResult*)person
                                    emailIndex:(NSInteger)index;

+ (instancetype)rowModelWithUser:(InfinitUser*)user;

+ (instancetype)rowModelWithEmail:(NSString*)email;

@end
