//
//  GetBSDProcessList.h
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#ifdef __cplusplus
extern "C"
{
#endif

# import <Foundation/Foundation.h>

# import <sys/sysctl.h>

typedef struct kinfo_proc kinfo_proc;

int GetBSDProcessList(kinfo_proc **procList, size_t *procCount);

#ifdef __cplusplus
}
#endif