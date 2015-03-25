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
      // Ensure that our libc++ and libc++abi are used.
      setenv("DYLD_ROOT_PATH", our_cxx_path.UTF8String, 1);
      NSString* fallback_path = @"/lib:/usr/lib";
      // Ensure that we fallback to the system paths for libraries. This is crucial because
      // DYLD_FALLBACK_LIBRARY_PATH defaults to $(HOME)/lib:/usr/local/lib:/lib:/usr/lib.
      // If you have Homebrew installed, it's libraries are at /usr/local/lib. Loading these can
      // cause missing symbols.
      setenv("DYLD_FALLBACK_LIBRARY_PATH", fallback_path.UTF8String, 1);
    }
    execvp(argv[0], argv);
  }
#endif
  return NSApplicationMain(argc, (const char **)argv);
}
