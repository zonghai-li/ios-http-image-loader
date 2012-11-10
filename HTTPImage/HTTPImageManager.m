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


#import "HTTPImageManager.h"
#import "NSOperationStack.h"
#import "HTTPImageDownloader.h"

#import "SLLGlobal.h"

#import <CommonCrypto/CommonHMAC.h>


////+++++++++++++++++++++++++++++++++++++++++++++++++++++
////    HTTPImageRequest
////+++++++++++++++++++++++++++++++++++++++++++++++++++++
@interface HTTPImageRequest()
{
    NSURL       *_url;
    NSString    *_hashedUrl;
    
    id          _delegate;
    UIView      *_target;
    
#ifdef NS_BLOCKS_AVAILABLE    
    HTTPImageCompletionBlock _completionBlock;
#endif
}

-(NSString *) keyForURL:(NSURL *)url;
-(void) initWithUrl:(NSString *)url;
@end


@implementation HTTPImageRequest
@synthesize url = _url;
@synthesize hashedUrl = _hashedUrl;
@synthesize target = _target;
@synthesize delegate = _delegate;
@synthesize tag;
@synthesize incrementally = _incrementally;

#ifdef NS_BLOCKS_AVAILABLE
@synthesize completionBlock = _completionBlock;
#endif

// borrowed from ASIHttp
-(NSString *) keyForURL:(NSURL *)url
{
	NSString *urlString = [url absoluteString];
	if ([urlString length] == 0) {
		return nil;
	}
    
	// Strip trailing slashes so http://allseeing-i.com/ASIHTTPRequest/ is cached the same as http://allseeing-i.com/ASIHTTPRequest
	if ([[urlString substringFromIndex:[urlString length]-1] isEqualToString:@"/"]) {
		urlString = [urlString substringToIndex:[urlString length]-1];
	}
    
	// Borrowed from: http://stackoverflow.com/questions/652300/using-md5-hash-on-a-string-in-cocoa
	const char *cStr = [urlString UTF8String];
	unsigned char result[16];
	CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
	return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],result[8], result[9], result[10], result[11],result[12], result[13], result[14], result[15]]; 	
}


-(void) initWithUrl:(NSString *)url;
{
    NSAssert (url && url.length > 0, @"empty url");
    
    _url = [[NSURL alloc] initWithString:url];
    _hashedUrl = sll_retain([self keyForURL:_url]); //compute hashed url
}


-(id) initWithURL:(NSString *)url
{
    if ((self = [super init]))
        [self initWithUrl:url];
    
    return self;
}


-(id) initWithURL:(NSString *)url andDelegate:(id)delegate
{
    if ((self = [super init]))
    {
        [self initWithUrl:url];
        _delegate = delegate;
    }
    return self;
}


-(id) initWithURL:(NSString *)url forUIView:(UIView *)v
{
    if ((self = [super init]))
    {
        [self initWithUrl:url];
        _target = sll_retain(v);
    }
    return self;
}


#ifdef NS_BLOCKS_AVAILABLE
-(id) initWithURL:(NSString *)url forUIView:(UIView *)v completionBlock:(HTTPImageCompletionBlock)block
{
    if ((self = [super init]))
    {
        [self initWithUrl:url];
        _target = sll_retain(v);
        _completionBlock = Block_copy(block);
    }
    return self;
}
#endif


+(id) requestWithURL:(NSString *)url
{
    return sll_autorelease([[HTTPImageRequest alloc] initWithURL:url]);
}


+(id) requestWithURL:(NSString *)url andDelegate:(id)delegate
{
    return sll_autorelease([[HTTPImageRequest alloc] initWithURL:url andDelegate:delegate]);
}


+(id) requestWithURL:(NSString *)url forUIView:(UIView *)v
{
    return sll_autorelease([[HTTPImageRequest alloc] initWithURL:url forUIView:v]);
}


#ifdef NS_BLOCKS_AVAILABLE
+(id) requestWithURL:(NSString *)url forUIView:(UIView *)v completionBlock:(HTTPImageCompletionBlock)block
{
    return sll_autorelease([[HTTPImageRequest alloc] initWithURL:url forUIView:v completionBlock:block]);
}
#endif


-(BOOL) isEqual:(id)object
{
    if([object isMemberOfClass:[HTTPImageRequest class]]) 
    {
       return [self.url isEqual:((HTTPImageRequest *)object).url];
    }
    return false;
}


-(NSUInteger) hash
{
    return [self.url hash];
}


-(void) dealloc
{
    sll_release(_url);
    sll_release(_hashedUrl);
    Block_release(_completionBlock);
    
    [super dealloc];
}
@end


////+++++++++++++++++++++++++++++++++++++++++++++++++++++
////    HTTPImageManager
////+++++++++++++++++++++++++++++++++++++++++++++++++++++

#define kMaxConcurrentOperation     4


@interface HTTPImageManager()
{
    NSOperationQueue *_greenpassQueue; // for loading local cache
    NSOperationQueue *_operationQueue;
    
    NSMutableDictionary *_bindings;
    NSRecursiveLock *_lock; // protect _bindings
    
    NSMutableSet *_activeRequests;
    NSCondition *_condvar; // for _activeRequests
}

-(void) _initWithType: (HTTPImageQueueType)type;
-(void) doLoadImage: (HTTPImageRequest *)request;
-(UIImage *) decodedImageWithImage:(UIImage *)image;
-(NSString *) boundHashedUrl:(UIView *)view;
-(void) bindView:(UIView *)view toHashedUrl:(NSString *)hashedUrl;
-(void) unbindView:(UIView *)view;

@end


@implementation HTTPImageManager 
@synthesize memoryCache = _memoryCache;
@synthesize persistence = _persistence;
@synthesize queueType = _queueType;


-(void) _initWithType: (HTTPImageQueueType)type
{
    _queueType = type;
    
    if (_queueType == kHTTPImageQueueFIFO) 
        _operationQueue = [[NSOperationQueue alloc] init];
    else if (_queueType == kHTTPImageQueueLIFO)
        _operationQueue = [[NSOperationStack alloc] init];
    
    _operationQueue.maxConcurrentOperationCount = kMaxConcurrentOperation;
    
    _greenpassQueue = [[NSOperationQueue alloc] init];
    _greenpassQueue.maxConcurrentOperationCount = 1;
    
    _bindings = [[NSMutableDictionary alloc] initWithCapacity:32];
    _activeRequests = [[NSMutableSet alloc] initWithCapacity:32];
    _lock = [[NSRecursiveLock alloc] init];
    _condvar = [[NSCondition alloc] init];
}


-(id) init
{
    if ((self = [super init]))
    {
        [self _initWithType:kHTTPImageQueueFIFO];    
    }
    return  self;
    
}


-(id) initWithType:(HTTPImageQueueType)type
{
    if ((self = [super init]))
    {
        [self _initWithType:type];
    }
    return self;
}


-(void) dealloc
{
    sll_release(_greenpassQueue);
    sll_release(_operationQueue);
    sll_release(_condvar);
    sll_release(_bindings);
    sll_release(_lock);
    sll_release(_activeRequests);
    
    [super dealloc];
}


-(UIImage *) loadImage:(HTTPImageRequest *)request
{
    NSAssert (request != nil && request.url != nil, @"empty request url");
    
    NSString *key = request.hashedUrl;
    UIView *v = request.target;
    
    if (v) 
    {
        // bind url to the target view
        [_lock lock];
        [self bindView:v toHashedUrl:request.hashedUrl];
        [_lock unlock];
    }
    
    UIImage *image = [_memoryCache loadImage: key];
    if (image) 
    {
        if (v)
        {
            if (request.completionBlock) 
                request.completionBlock(image);
            else if ([v isKindOfClass:[UIImageView class]]) 
                ((UIImageView *)v).image = image;
            else if ([v isKindOfClass:[UIButton class]]) 
                [((UIButton *)v) setImage:image forState:UIControlStateNormal];
        }
        return image;
    }
    
    //not ready yet, try to retrieve it asynchronously
    
    sll_retain(request);
    
    if (_persistence && [_persistence exists:key] && _operationQueue.operationCount > kMaxConcurrentOperation)
    {
        [_greenpassQueue addOperationWithBlock:^{
            [self doLoadImage:request];
        }];
    }
    else 
    {
        [_operationQueue addOperationWithBlock:^{
            [self doLoadImage:request];
        }];
    }
    
    return nil;
}


-(UIImage *) loadImageIncrementally:(HTTPImageRequest *)request
{
    request.incrementally = YES;
    return [self loadImage:request];
}


-(void) doLoadImage:(HTTPImageRequest *)request
{
    if (request.target) 
    {
        [_lock lock];
        NSString *hashedUrl = [self boundHashedUrl:request.target];
        if (![hashedUrl isEqual:request.hashedUrl])
        {
            // The target view is not representing the url any more.  This means the target view has been reused 
            // during a scrolling operation (of a tableview).
            SLLog("give up loading %@", request.url);
            sll_saferelease(request);
            [_lock unlock];
            return;
        }
        [_lock unlock];
    }
    
    [_condvar lock];
    while ([_activeRequests member:request]) 
    {
        //If there's been already request pending for the same URL, we just wait until it is handled.
        SLLog("penging request: %@", request.url);
        [_condvar waitUntilDate:[NSDate distantFuture]];
    }
    [_activeRequests addObject:request];
    sll_release(request); // since it is retained by _activeRequests
    [_condvar unlock];
    
    UIImage *image = nil;
    NSString *key = request.hashedUrl;
    
    @try 
    {
        //first we lookup memory cache
        if (_memoryCache) 
            image = [_memoryCache loadImage:key];
        
        if (!image)
        {
            //then check the persistent storage
            if (_persistence)
                image = [_persistence loadImage:key];
            if (image)
            {
                SLLog("found in persistent storage: %@", request.url);
                
                image = [self decodedImageWithImage:image]; // immediate decoding
                if (_memoryCache) 
                    [_memoryCache storeImage:image forKey:key]; // store it in memory cache
                
            }
            else 
            {
                SLLog("go to network: %@", request.url);
                NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
                
                HTTPImageDownloader *downloader = [[HTTPImageDownloader alloc] init];
                
                NSError *error = nil;
                NSData *imageData = [downloader download:request error:&error];
                if (error) 
                {
                    @throw [NSException exceptionWithName:@"HTTPImageManager" 
                                                   reason:@"" 
                                                 userInfo:[NSDictionary dictionaryWithObject:error forKey:@"nserror"]];
                }
                
                image = [UIImage imageWithData:imageData];
                if (!image) 
                    [NSException raise:@"HTTPImageManager" format:@"bad data: %@", request.url];
                
                image = [self decodedImageWithImage:image]; // force decoding
                if (!image) 
                    [NSException raise:@"HTTPImageManager" format:@"failed decoding image: %@", request.url];
                
                SLLog("image decoded: size= time consumed=%fsec", [[NSDate date] timeIntervalSince1970 ] - start);
                
                if (_memoryCache) 
                    [_memoryCache storeImage:image forKey:key]; // load it into memory
                
                if (_persistence)
                    [_persistence storeImage:imageData forKey:key]; // persist it
                
                sll_saferelease(downloader);
            }
        }
        
        if(image && request.target)
        {
            [_lock lock];
            NSString *hashedUrl = [self boundHashedUrl:request.target];
            if ([hashedUrl isEqual:request.hashedUrl])
            {
                sll_retain(image);
                dispatch_async(dispatch_get_main_queue(), ^{
                    sll_autorelease(image);
                    UIView *v = request.target;
                    if (request.completionBlock) 
                        request.completionBlock(image);
                    else if ([v isKindOfClass:[UIImageView class]]) 
                        ((UIImageView *)v).image = image;
                    else if ([v isKindOfClass:[UIButton class]]) 
                        [((UIButton *)v) setImage:image forState:UIControlStateNormal];
                });
                
                [self unbindView:request.target];
            }
            else 
            {
                SLLog("view not representing this url: %@", request.url);
            }
            [_lock unlock];
        }
        
        // callback delegate on the main thread
        if ([request.delegate respondsToSelector:@selector(request:didLoadWithImage:)]) 
        {
            sll_retain(request);
            sll_retain(image);
            dispatch_async(dispatch_get_main_queue(), ^{
                sll_autorelease(request);
                sll_autorelease(image);
                [request.delegate request:request didLoadWithImage:image];
            });
            
        }
    }
    @catch (NSException *exception) 
    {
        if (request.target) 
        {
            [_lock lock];
            NSString *hashedUrl = [self boundHashedUrl:request.target];
            if ([hashedUrl isEqual:request.hashedUrl])
                [self unbindView:request.target];
            [_lock unlock];
        }
        
        // callback delegate on main thread
        
        NSError *error = [exception.userInfo objectForKey:@"nserror"];
        if (request.delegate && [request.delegate respondsToSelector:@selector(request:didFail:)]) 
        {
            sll_retain(request);
            dispatch_async(dispatch_get_main_queue(), ^{
                sll_autorelease(request);
                [request.delegate request:request didFail:error];
            });
        }
    
        SLLog("error handling request: %@ (%@)", request.url, (error ? error.description : exception.description));
    }
    @finally 
    {
        [_condvar lock];
        [_activeRequests removeObject:request];
        [_condvar signal];
        [_condvar unlock];
        
        SLLog("finished request for: %@", request.url);
    }
    
}


-(void) bindView:(UIView *)view toHashedUrl:(NSString *)hashedUrl
{
    objc_objectptr_t p = objc_unretainedPointer(view);
    NSNumber *targetRef = [NSNumber numberWithLong:(long)p];
    if ([_bindings objectForKey:targetRef]) 
        [_bindings removeObjectForKey:targetRef];
    [_bindings setObject:hashedUrl forKey:targetRef];
}


-(void) unbindView:(UIView *)view
{
    objc_objectptr_t p = objc_unretainedPointer(view);
    NSNumber *targetRef = [NSNumber numberWithLong:(long)p];
    [_bindings removeObjectForKey:targetRef];
}


-(NSString *)boundHashedUrl:(UIView *)view
{
    objc_objectptr_t p = objc_unretainedPointer(view);
    NSNumber *targetRef = [NSNumber numberWithLong:(long)p];
    return [_bindings objectForKey:targetRef];
}


- (UIImage *)decodedImageWithImage:(UIImage *)image
{
    CGImageRef imageRef = image.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 CGImageGetWidth(imageRef),
                                                 CGImageGetHeight(imageRef),
                                                 8,
                                                 // Just always return width * 4 will be enough
                                                 CGImageGetWidth(imageRef) * 4,
                                                 // System only supports RGB, set explicitly
                                                 colorSpace,
                                                 // Makes system don't need to do extra conversion when displayed.
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little); 
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;
    
    CGRect rect = (CGRect){CGPointZero,{CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)}};
    CGContextDrawImage(context, rect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *decompressedImage = [[UIImage alloc] initWithCGImage:decompressedImageRef scale:image.scale orientation:UIImageOrientationUp];
    CGImageRelease(decompressedImageRef);
    return [decompressedImage autorelease];
}

@end
