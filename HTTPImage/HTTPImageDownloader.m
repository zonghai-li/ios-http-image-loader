//  Copyright 2012 Zonghai Li. All rights reserved.
//
//  Redistribution and use in binary and source forms, with or without modification,
//  are permitted for any project, commercial or otherwise, provided that the
//  following conditions are met:
//  
//  Redistributions in binary form must display the copyright notice in the About
//  view, website, and/or documentation.
//  
//  Redistributions of source code must retain the copyright notice, this list of
//  conditions, and the following disclaimer.
//
//  THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
//  PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THIS SOFTWARE.


#import "HTTPImageDownloader.h"
#import "HTTPImageManager.h"

#import "SLLGlobal.h"

#import <ImageIO/ImageIO.h>


@interface HTTPImageDownloader() 
{
    NSURLConnection     *_connection;
    NSUInteger          _expectedSize;
    NSMutableData       *_imageData;
    size_t              _width, _height;
    NSError             *_error;
    HTTPImageRequest    *_request;
    BOOL                _completed;
}
@end


@implementation HTTPImageDownloader

-(void) dealloc
{
    sll_release(_imageData);
    sll_release(_connection);
    sll_release(_error);
    
    [super dealloc];
}


-(NSData *)download:(HTTPImageRequest *)request error:(NSError **)error
{    
    _request = request;
    _completed = NO;
    
    NSURLRequest *urlRequest =sll_autorelease([[NSURLRequest alloc] initWithURL:request.url 
                                                     cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                                 timeoutInterval:10]);
    
    _connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:NO];
    
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    
    NSString * const kThisSpecificRunLoopMode = @"HTTPImageDownloaderRunLoopMode";
    //ensure we aren't blocked by UI manipulations by using a custom mode
    [_connection scheduleInRunLoop:runloop forMode:kThisSpecificRunLoopMode];
    [_connection start];

    do 
    {
        //sort of polling the event for setting the "_completed" flag
        if (![runloop runMode:kThisSpecificRunLoopMode
              beforeDate:[NSDate dateWithTimeIntervalSinceNow:10.0]]) 
        {
            SLLog("WARNING: runloop not start!");
            _completed = YES;
        }
        
    }
    while (!_completed);
    
    if(_error) *error = _error;
    return _imageData;
}


#pragma mark NSURLConnection (delegate)

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response
{
    if (![response respondsToSelector:@selector(statusCode)] || ((NSHTTPURLResponse *)response).statusCode < 400)
    {
        _expectedSize = response.expectedContentLength > 0 ? (NSUInteger)response.expectedContentLength : 0;
        _imageData = [[NSMutableData alloc] initWithCapacity:_expectedSize];
        
        if ([_request.delegate respondsToSelector:@selector(request:didUpdateProgress:ofTotalSize:)]) 
        {
            sll_retain(_request);
            dispatch_async(dispatch_get_main_queue(), ^{
                sll_autorelease(_request);
                [_request.delegate request:_request didUpdateProgress:0 ofTotalSize:_expectedSize];
            });
        }

    }
    else
    {
        [_connection cancel];
        sll_saferelease(_connection);
        _error = sll_retain([NSError errorWithDomain:@"HTTPImageDownloader" 
                                                code:((NSHTTPURLResponse *)response).statusCode 
                                            userInfo:nil]);
        _completed = YES;
    }
}


- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data
{
    [_imageData appendData:data];
    
    //update progress
    if ([_request.delegate respondsToSelector:@selector(request:didUpdateProgress:ofTotalSize:)]) 
    {
        sll_retain(_request);
        dispatch_async(dispatch_get_main_queue(), ^{
            sll_autorelease(_request);
            [_request.delegate request:_request didUpdateProgress:_imageData.length ofTotalSize:_expectedSize];
        });
    }
    
    /*
     Part of the rest of code in this function is from SDWebImage. License:
     
     Copyright (c) 2009 Olivier Poitrey <rs@dailymotion.com>
     
     Permission is hereby granted, free of charge, to any person obtaining a copy
     of this software and associated documentation files (the "Software"), to deal
     in the Software without restriction, including without limitation the rights
     to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
     copies of the Software, and to permit persons to whom the Software is furnished
     to do so, subject to the following conditions:
     */
    if (CGImageSourceCreateImageAtIndex == NULL)
    {
        // ImageIO isn't present in iOS < 4
        _request.incrementally = NO;
    }
    
    if (_request.incrementally 
        && _expectedSize > 0 
        && ([_request.delegate respondsToSelector:@selector(request:didUpdatePartialImage:)]))
    {
        // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
        // Thanks to the author @Nyx0uf
        
        // Get the total bytes downloaded
        const NSUInteger totalSize = [_imageData length];
        
        // Update the data source, we must pass ALL the data, not just the new bytes
        CGImageSourceRef imageSource = CGImageSourceCreateIncremental(NULL);
        CGImageSourceUpdateData(imageSource, (__bridge CFDataRef)_imageData, totalSize == _expectedSize);
        
        if (_width + _height == 0)
        {
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
            if (properties)
            {
                CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &_height);
                val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &_width);
                CFRelease(properties);
            }
        }
        
        if (_width + _height > 0 && totalSize < _expectedSize)
        {
            // Create the image
            CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
            
#ifdef TARGET_OS_IPHONE
            // Workaround for iOS anamorphic image
            if (partialImageRef)
            {
                const size_t partialHeight = CGImageGetHeight(partialImageRef);
                CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                CGContextRef bmContext = CGBitmapContextCreate(NULL, _width, _height, 8, _width * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
                CGColorSpaceRelease(colorSpace);
                if (bmContext)
                {
                    CGContextDrawImage(bmContext, CGRectMake(0, 0, _width, partialHeight), partialImageRef);
                    CGImageRelease(partialImageRef);
                    partialImageRef = CGBitmapContextCreateImage(bmContext);
                    CGContextRelease(bmContext);
                }
                else
                {
                    CGImageRelease(partialImageRef);
                    partialImageRef = nil;
                }
            }
#endif
            if (partialImageRef)
            {
                UIImage *partialImage = [UIImage imageWithCGImage: partialImageRef];
                sll_retain(partialImage);
                sll_retain(_request);
                dispatch_async(dispatch_get_main_queue(), ^{
                    sll_autorelease(_request);
                    sll_autorelease(partialImage);
                    [_request.delegate request:_request didUpdatePartialImage:partialImage];
                    
                });

                CGImageRelease(partialImageRef);
            }
        }
        
        CFRelease(imageSource);
    }
}


#pragma GCC diagnostic ignored "-Wundeclared-selector"
- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
    sll_saferelease(_connection);   
    _completed = YES;
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    sll_saferelease(_connection);
    sll_saferelease(_imageData);
    _error = sll_retain(error);
    _completed = YES;
}
@end
