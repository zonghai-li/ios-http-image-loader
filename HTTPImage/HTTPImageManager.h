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
#import "ImageCacheProtocol.h"
#import "BasicMemoryCache.h"
#import "FilePersistence.h"
#import "UIButton+HTTPImage.h"
#import "UIImageView+HTTPImage.h"

#import <UIKit/UIKit.h>


typedef enum {
    kHTTPImageQueueLIFO,
    kHTTPImageQueueFIFO,
} HTTPImageQueueType;


// Delegate. The delegates are called on the main thread
@class HTTPImageRequest;
@protocol HTTPImageRequestDelegate <NSObject>
@optional
-(void) request:(HTTPImageRequest *)request didLoadWithImage:(UIImage *)image;
-(void) request:(HTTPImageRequest *)request didFail:(NSError *)error;
-(void) request:(HTTPImageRequest *)request didUpdateProgress:(NSUInteger)loadSize ofTotalSize: (NSUInteger)totalSize;
//incrementally loading image
-(void) request:(HTTPImageRequest *)request didUpdatePartialImage:(UIImage *)partialImage;
@end


//Block
#ifdef NS_BLOCKS_AVAILABLE
typedef void (^HTTPImageCompletionBlock)(UIImage *image);
#endif


@interface HTTPImageRequest : NSObject
@property(nonatomic) NSInteger tag;
@property(nonatomic, readonly) NSURL *url;
@property(nonatomic, readonly) NSString *hashedUrl;
@property(nonatomic, retain) UIView *target;
@property(nonatomic, readonly) HTTPImageCompletionBlock completionBlock;

@property(nonatomic, assign) id<HTTPImageRequestDelegate> delegate;

//see http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
@property(nonatomic) BOOL incrementally;

-(id) initWithURL:(NSString *)url;
-(id) initWithURL:(NSString *)url andDelegate:(id)delegate;

-(id) initWithURL:(NSString *)url forUIView: (UIView *)v;
#ifdef NS_BLOCKS_AVAILABLE
-(id) initWithURL:(NSString *)url forUIView: (UIView *)v completionBlock: (HTTPImageCompletionBlock)block;
#endif

+(id) requestWithURL:(NSString *)url;
+(id) requestWithURL:(NSString *)url andDelegate:(id)delegate;
+(id) requestWithURL:(NSString *)url forUIView: (UIView *)v;

#ifdef NS_BLOCKS_AVAILABLE
+(id) requestWithURL:(NSString *)url forUIView: (UIView *)v completionBlock: (HTTPImageCompletionBlock)block;
#endif
@end


@protocol ImageCacheProtocol;
@interface HTTPImageManager : NSOperation 

@property(nonatomic, retain) id<ImageCacheProtocol> memoryCache;
@property(nonatomic, retain) id<ImageCacheProtocol> persistence;
@property(nonatomic, readonly) HTTPImageQueueType queueType;

-(id) initWithType: (HTTPImageQueueType)type;
-(UIImage *) loadImage:(HTTPImageRequest *)request;

//incrementally loading and updating image
-(UIImage *) loadImageIncrementally:(HTTPImageRequest *)request;

@end
