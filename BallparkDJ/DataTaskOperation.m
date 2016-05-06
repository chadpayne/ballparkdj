//
//  DataTaskOperation.m
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/5/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

#import "DataTaskOperation.h"

@interface DataTaskOperation ()

@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, weak) NSURLSessionTask *task;
@property (nonatomic, copy) void (^dataTaskCompletionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);

@end

@implementation DataTaskOperation

- (instancetype)initWithRequest:(NSURLRequest *)request dataTaskCompletionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))dataTaskCompletionHandler {
    self = [super init];
    if (self) {
        self.request = request;
        self.dataTaskCompletionHandler = dataTaskCompletionHandler;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url dataTaskCompletionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))dataTaskCompletionHandler {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    return [self initWithRequest:request dataTaskCompletionHandler:dataTaskCompletionHandler];
}

- (void)main {
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:self.request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        self.dataTaskCompletionHandler(data, response, error);
        [self completeOperation];
    }];
    
    [task resume];
    self.task = task;
}

- (void)completeOperation {
    self.dataTaskCompletionHandler = nil;
    [super completeOperation];
}

- (void)cancel {
    [self.task cancel];
    [super cancel];
}

@end