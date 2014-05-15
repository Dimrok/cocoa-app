//
//  InfinitLinkIconManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 15/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkIconManager.h"

@implementation InfinitLinkIconManager

+ (NSString*)extensionForFile:(NSString*)filename
{
  if (filename.length == 0 || [filename rangeOfString:@"."].location == NSNotFound)
    return @"";
  NSInteger i = filename.length - 1;
  NSMutableString* extension = [NSMutableString string];
  while (i > 0 && [filename characterAtIndex:i] != '.')
  {
    [extension insertString:[NSString stringWithFormat:@"%c", [filename characterAtIndex:i]] atIndex:0];
    i--;
  }
  return extension;
}

+ (NSImage*)iconForFilename:(NSString*)filename
{
  NSImage* res;
  CFStringRef extension = (__bridge CFStringRef)[InfinitLinkIconManager extensionForFile:filename];
  CFStringRef fileUTI =
    UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);

  if (UTTypeConformsTo(fileUTI, kUTTypeImage))
  {
    if (UTTypeEqual(fileUTI, kUTTypeGIF))
      res = [IAFunctions imageNamed:@"cat"];
    else if (UTTypeEqual(fileUTI, (__bridge CFStringRef)@"com.adobe.illustrator.ai-image"))
      res = [IAFunctions imageNamed:@"illustrator"];
    else if (UTTypeEqual(fileUTI, (__bridge CFStringRef)@"com.adobe.photoshop-image"))
      res = [IAFunctions imageNamed:@"photoshop"];
    else
      res = [IAFunctions imageNamed:@"picture"];
  }
  else if (UTTypeConformsTo(fileUTI, kUTTypeMovie))
  {
    res = [IAFunctions imageNamed:@"video"];
  }
  else if(UTTypeConformsTo(fileUTI, kUTTypeAudio))
  {
    res = [IAFunctions imageNamed:@"music"];
  }
  else if (UTTypeConformsTo(fileUTI, kUTTypeText) ||
           UTTypeConformsTo(fileUTI, kUTTypeTXNTextAndMultimediaData) ||
           UTTypeConformsTo(fileUTI, (__bridge CFStringRef)@"com.adobe.pdf") ||
           UTTypeConformsTo(fileUTI, (__bridge CFStringRef)@"com.microsoft.word.doc") ||
           UTTypeConformsTo(fileUTI, (__bridge CFStringRef)@"com.apple.iwork.pages.sffpages"))
  {
    res = [IAFunctions imageNamed:@"document"];
  }
  else if (UTTypeConformsTo(fileUTI, kUTTypeCompositeContent) ||
           UTTypeConformsTo(fileUTI, (__bridge CFStringRef)@"public.presentation") ||
           UTTypeConformsTo(fileUTI, (__bridge CFStringRef)@"com.apple.iwork.numbers.sffnumbers")||
           UTTypeConformsTo(fileUTI, (__bridge CFStringRef)@"com.microsoft.excel.xls"))
  {
    res = [IAFunctions imageNamed:@"powerpoint"];
  }
  else if (UTTypeConformsTo(fileUTI, kUTTypeArchive))
  {
    res = [IAFunctions imageNamed:@"archive"];
  }
  else
  {
    res = [IAFunctions imageNamed:@"folder"];
  }
  CFRelease(fileUTI);

  return res;
}

@end
