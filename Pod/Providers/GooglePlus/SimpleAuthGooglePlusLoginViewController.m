//
//  SimpleAuthGooglePlusLoginViewController.m
//  SimpleAuth
//
//  Created by Martin Pilch on 16/5/15.
//  Copyright (c) 2015 Martin Pilch, All rights reserved.
//

#import "SimpleAuthGooglePlusLoginViewController.h"

@implementation SimpleAuthGooglePlusLoginViewController

#pr
#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"Google +";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
    NSDictionary *parameters = @{
        @"client_id" : self.options[@"client_id"],
        @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
        @"response_type" : @"code",
        @"scope" : self.options[@"scope"]
    };
    NSString *URLString = [NSString stringWithFormat:
                           @"https://accounts.google.com/o/oauth2/auth?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
