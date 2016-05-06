//
//  AsynchronousOperation.m
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/5/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

@import Foundation;

@interface AsynchronousOperation : NSOperation

/// Complete the asynchronous operation.
///
/// This also triggers the necessary KVO to support asynchronous operations.

- (void)completeOperation;

@end