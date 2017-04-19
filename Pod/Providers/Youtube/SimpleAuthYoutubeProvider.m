//
//  SimpleAuthYoutubeProvider.m
//  SimpleAuth
//
//  Created by Martin Pilch on 16/5/15.
//  Copyright (c) 2015 Martin Pilch, All rights reserved.
//

#import "SimpleAuthYoutubeProvider.h"
#import "SimpleAuthYoutubeLoginViewController.h"

#import "UIViewController+SimpleAuthAdditions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation SimpleAuthYoutubeProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"youtube";
}

+ (NSDictionary *)defaultOptions {
    
    // Default present block
    SimpleAuthInterfaceHandler presentBlock = ^(UIViewController *controller) {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        UIViewController *presentedViewController = [UIViewController SimpleAuth_presentedViewController];
        [presentedViewController presentViewController:navigationController
                                              animated:YES
                                            completion:nil];
    };
    
    // Default dismiss block
    SimpleAuthInterfaceHandler dismissBlock = ^(id viewController) {
        [viewController dismissViewControllerAnimated:YES
                                           completion:nil];
    };
    
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:[super defaultOptions]];
    options[SimpleAuthPresentInterfaceBlockKey] = presentBlock;
    options[SimpleAuthDismissInterfaceBlockKey] = dismissBlock;
    options[SimpleAuthRedirectURIKey] = @"http://localhost";
    options[@"scope"] = @"email openid profile https://www.googleapis.com/auth/youtube";
    options[@"access_type"] = @"offline";
    return options;
}

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        SimpleAuthYoutubeLoginViewController *loginViewController = [[SimpleAuthYoutubeLoginViewController alloc] initWithOptions:self.options];
        loginViewController.completion = ^(UIViewController *viewController, NSURL *URL, NSError *error) {
            SimpleAuthInterfaceHandler dismissBlock = self.options[SimpleAuthDismissInterfaceBlockKey];
            dismissBlock(viewController);
            
            NSString *query = [URL query];
            NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:query];
            NSString *code = dictionary[@"code"];
            if ([code length] > 0) {
                [self userWithCode:code
                        completion:completion];
            } else {
                completion(nil, error);
            }
        };
        SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
        block(loginViewController);
    });
}

#pragma mark - Private
- (void)userWithCode:(NSString *)code completion:(SimpleAuthRequestHandler)completion
{
    NSDictionary *parameters = @{ @"code" : code,
                                  @"client_id" : self.options[@"client_id"],
                                  @"redirect_uri": self.options[@"redirect_uri"],
                                  @"grant_type": @"authorization_code"};
    
    NSString *data = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
    
    NSString *URLString = [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
                               NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                               if ([indexSet containsIndex:statusCode] && data) {
                                   NSError *parseError;
                                   NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                                              options:kNilOptions
                                                                                                error:&parseError];
                                   NSString *token = dictionary[@"access_token"];
                                   if ([token length] > 0) {
                                       
                                       NSDictionary *credentials = @{
                                                                     @"access_token" : token,
                                                                     @"expires" : [NSDate dateWithTimeIntervalSinceNow:[dictionary[@"expires_in"] doubleValue]],
                                                                     @"token_type" : @"bearer",
                                                                     @"refresh_token": dictionary[@"refresh_token"]
                                                                     };
                                       
                                       [self userWithCredentials:credentials
                                                      completion:completion];
                                   } else {
                                       completion(nil, parseError);
                                   }
                                   
                               } else {
                                   completion(nil, connectionError);
                               }
                           }];
}


- (void)userWithCredentials:(NSDictionary *)credentials completion:(SimpleAuthRequestHandler)completion {
    
    NSString *URLString = [NSString stringWithFormat:@"https://www.googleapis.com/userinfo/v2/me"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@", credentials[@"access_token"]] forHTTPHeaderField:@"Authorization"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
                               NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                               if ([indexSet containsIndex:statusCode] && data) {
                                   NSError *parseError;
                                   NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:data
                                                                                            options:kNilOptions
                                                                                              error:&parseError];
                                   if (userInfo) {
                                       [self userDataWithAccount:userInfo
                                                     credentials:credentials
                                                      completion:completion];
                                   } else {
                                       completion(nil, parseError);
                                   }
                               } else {
                                   completion(nil, connectionError);
                               }
                           }];
}

- (void)userDataWithAccount:(NSDictionary *)account
                credentials:(NSDictionary *)credentials
                 completion:(SimpleAuthRequestHandler)completion
{
    NSString *URLString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/subscriptions?part=snippet&mySubscribers=true"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@", credentials[@"access_token"]] forHTTPHeaderField:@"Authorization"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
                               NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                               if ([indexSet containsIndex:statusCode] && data) {
                                   NSError *parseError;
                                   NSDictionary *subscriptionsInfo = [NSJSONSerialization JSONObjectWithData:data
                                                                                                     options:kNilOptions
                                                                                                       error:&parseError];
                                   
                                   NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
                                   
                                   // Provider
                                   dictionary[@"provider"] = [[self class] type];
                                   
                                   // Credentials
                                   dictionary[@"credentials"] = @{
                                                                  @"token" : credentials[@"access_token"],
                                                                  @"refresh_token" : credentials[@"refresh_token"],
                                                                  @"expires_at" : credentials[@"expires"]
                                                                  };
                                   
                                   // User ID
                                   dictionary[@"uid"] = account[@"id"];
                                   
                                   NSMutableDictionary *accountDict = [NSMutableDictionary dictionaryWithDictionary:account];
                                   accountDict[@"subscribers"] = subscriptionsInfo[@"pageInfo"][@"totalResults"];
                                   
                                   // Raw response
                                   dictionary[@"extra"] = @{
                                                            @"raw_info" : accountDict
                                                            };
                                   
                                   // User info
                                   NSMutableDictionary *user = [NSMutableDictionary new];
                                   user[@"name"] = account[@"name"] ? account[@"name"] : @"";
                                   user[@"gender"] = account[@"gender"] ? account[@"gender"] : @"";
                                   
                                   user[@"image"] = account[@"picture"] ? account[@"picture"] : @"";
                                   
                                   dictionary[@"info"] = user;
                                   
                                   if (subscriptionsInfo) {
                                       completion (dictionary, nil);
                                   } else {
                                       completion(nil, parseError);
                                   }
                               } else {
                                   completion(nil, connectionError);
                               }
                           }];
}

@end
