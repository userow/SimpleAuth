//
//  UIWindow+SimpleAuthAdditions.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/14/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "UIWindow+SimpleAuthAdditions.h"

@implementation UIWindow (SimpleAuthAdditions)

+ (instancetype)SimpleAuth_mainWindow {
#ifndef APP_EXTENSION
    return [[[UIApplication sharedApplication] delegate] window];
#endif
    return nil;
}

@end
