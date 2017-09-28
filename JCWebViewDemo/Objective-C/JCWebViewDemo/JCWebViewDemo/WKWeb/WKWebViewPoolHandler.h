//
//  WKWebViewPoolHandler.h
//  Pods
//
//  Created by zhengjiacheng on 2017/3/30.
//
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface WKWebViewPoolHandler : NSObject

+ (instancetype)sharedInstance;

- (WKProcessPool *)defaultPool;

@end
