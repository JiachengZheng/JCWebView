//
//  WKWebViewPoolHandler.m
//  Pods
//
//  Created by zhengjiacheng on 2017/3/30.
//
//

#import "WKWebViewPoolHandler.h"

@interface WKWebViewPoolHandler()
@property (nonatomic, strong) WKProcessPool *pool;
@end

@implementation WKWebViewPoolHandler

+ (instancetype)sharedInstance{
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance= [[self alloc] initPrivate];
    });
    return sharedInstance;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        self.pool = [WKProcessPool new];
    }
    return self;
}

- (WKProcessPool *)defaultPool{
    return self.pool;
}





@end
