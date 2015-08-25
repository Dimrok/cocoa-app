//
//  main.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitOSVersion.h"

int main(int argc, char *argv[])
{
#if !DEBUG
  @autoreleasepool
  {
    // Only need to change the library path on versions older than 10.9.
    SInt32 minor = [InfinitOSVersion osVersion].minor;
    if (minor != 0 && minor < 9 && !getenv("DYLD_LIBRARY_PATH"))
    {
      // Setting the library path ensures that on 10.7 and 10.8, the application loads the correct
      // libc++.
      NSString* framework_path = [NSBundle mainBundle].privateFrameworksPath;
      setenv("DYLD_LIBRARY_PATH", framework_path.UTF8String, 1);
      // Moving /usr/local/lib to the end of the fallback library path ensures that we don't get
      // polluted by Homebrew.
      NSString* fallback_paths = @"/lib:/usr/lib:/usr/local/lib";
      setenv("DYLD_FALLBACK_LIBRARY_PATH", fallback_paths.UTF8String, 1);
      execvp(argv[0], argv);
    }
  }
#endif
  return NSApplicationMain(argc, (const char**)argv);
}
