//
//  SimpleAuthGoogleLoginViewController.m
//  SimpleAuth
//
//  Created by Martin Pilch on 16/5/15.
//  Copyright (c) 2015 Martin Pilch, All rights reserved.
//

#import "SimpleAuthGoogleLoginViewController.h"

@implementation SimpleAuthGoogleLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"Google";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"client_id"] = self.options[@"client_id"];
    parameters[@"redirect_uri"] = @"http://localhost";
    parameters[@"response_type"] = @"code";
    parameters[@"state"] = self.options[@"state"];
    if (self.options[@"scope"]) {
        parameters[@"scope"] = [self.options[@"scope"] componentsJoinedByString:@" "];
    }
    NSString *URLString = [NSString stringWithFormat:
                           @"https://accounts.google.com/o/oauth2/auth?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
