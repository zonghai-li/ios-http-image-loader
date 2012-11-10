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


#import "FilePersistence.h"

#import "SLLGlobal.h"


@interface FilePersistence() 
{
    NSString *_basePath;
    NSTimeInterval _cacheInterval;
    NSFileManager *_manager;
}

-(void) _initWithPath:(NSString *)path withCacheInterval:(NSTimeInterval)cacheInterval;
-(BOOL) _exists:(NSString *)path;
@end


@implementation FilePersistence

-(id) initWithPath:(NSString *)path
{
    if ((self = [super init]))
    {
        [self _initWithPath:path withCacheInterval:HTTPImageFileCachePermanentInterval];
    }
    return self;
}


-(id) initWithPath:(NSString *)path withCacheInterval:(NSTimeInterval)cacheInterval
{
    if ((self = [super init]))
    {
        [self _initWithPath:path withCacheInterval:cacheInterval];
    }
    return self;
}


-(void) _initWithPath:(NSString *)path withCacheInterval:(NSTimeInterval)cacheInterval
{
    NSAssert( path != nil, @"empty path");
    
    _manager = [NSFileManager defaultManager];
    
    BOOL isDirectory = FALSE;
	if (![_manager fileExistsAtPath:path isDirectory:&isDirectory])
    {
		[_manager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
	}
    else 
    {
        NSAssert( isDirectory, @"%@ not directory", path);
    }
    
    _basePath = sll_retain(path);
    _cacheInterval = cacheInterval;
}


-(void) dealloc
{
    sll_release(_basePath);
    
    [super dealloc];
}


-(BOOL) exists:(NSString *)key
{
    if (_cacheInterval == HTTPImageFileCacheNoCache) return NO;
    
    //not testing expiration?
    return [self _exists:[_basePath stringByAppendingPathComponent:key]];
}


-(BOOL) _exists:(NSString *)path
{
    return [_manager fileExistsAtPath:path];
}


-(void) invalidate:(NSString *)key
{
    NSString *path = [_basePath stringByAppendingPathComponent:key];
    if([self _exists:path])
        [_manager removeItemAtPath:path error:NULL];
}


-(void) storeImage:(id)data forKey :(NSString *)key
{
    if (_cacheInterval != HTTPImageFileCacheNoCache) 
    {
        NSString *path = [_basePath stringByAppendingPathComponent:key];
        
        NSError *error = nil;
        if ([self _exists:path])
            [_manager removeItemAtPath:path error:&error];
        
        [data writeToFile:path options:NSDataWritingAtomic error:&error];
        if(error) SLLog("WARNING: write image to file failed: %@", error );
    }
}


-(UIImage *)loadImage:(NSString *)key
{
    if (_cacheInterval == HTTPImageFileCacheNoCache) return nil;
    
    NSString *path = [_basePath stringByAppendingPathComponent:key];
    
    if (![self _exists:path]) return nil;

    BOOL valid = YES;
    if (_cacheInterval > 0) 
    {
        NSError *error = nil;
        NSDictionary *attr = [_manager attributesOfItemAtPath:path error:&error];
        if (!error)
        {
            NSDate *ctime = [attr objectForKey:NSFileCreationDate];
            if (ctime && ABS(ctime.timeIntervalSinceNow) > _cacheInterval) 
                valid = NO;
        }
        else 
        {
            SLLog("WARNING: read attributes of file failed: %@", error);
        }
    }
    
    return (valid ? [UIImage imageWithContentsOfFile:path] : nil); 
}


-(void) clear
{
    [_manager removeItemAtPath:_basePath error:NULL];
}
@end
