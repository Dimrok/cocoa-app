//
//  main.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
#ifndef DEBUG
  if (!getenv("DYLD_ROOT_PATH"))
  {
    @autoreleasepool
    {
      NSString* our_cxx_path = [NSBundle mainBundle].privateFrameworksPath;
      setenv("DYLD_ROOT_PATH", our_cxx_path.UTF8String, 1);
    }
    execvp(argv[0], argv);
  }
#endif
  return NSApplicationMain(argc, (const char **)argv);
}
