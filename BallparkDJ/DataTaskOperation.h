//
//  DataTaskOperation.m
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/5/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//


@import Foundation;
#import "AsynchronousOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface DataTaskOperation : AsynchronousOperation

/// Creates a operation that retrieves the contents of a URL based on the specified URL request object, and calls a handler upon completion.
///
/// @param  request                    A NSURLRequest object that provides the URL, cache policy, request type, body data or body stream, and so on.
/// @param  dataTaskCompletionHandler  The completion handler to call when the load request is complete. This handler is executed on the delegate queue. This completion handler takes the following parameters:
///
/// @returns                           The new session data operation.

- (instancetype)initWithRequest:(NSURLRequest *)request dataTaskCompletionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))dataTaskCompletionHandler;

/// Creates a operation that retrieves the contents of a URL based on the specified URL request object, and calls a handler upon completion.
///
/// @param  url                        A NSURL object that provides the URL, cache policy, request type, body data or body stream, and so on.
/// @param  dataTaskCompletionHandler  The completion handler to call when the load request is complete. This handler is executed on the delegate queue. This completion handler takes the following parameters:
///
/// @returns                           The new session data operation.

- (instancetype)initWithURL:(NSURL *)url dataTaskCompletionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))dataTaskCompletionHandler;

@end

NS_ASSUME_NONNULL_END