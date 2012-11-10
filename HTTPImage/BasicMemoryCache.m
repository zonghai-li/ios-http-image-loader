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


#import "BasicMemoryCache.h"

#import "SLLGlobal.h"


@interface CacheEntry : NSObject

@property(nonatomic) NSInteger refCount;
@property(nonatomic) NSTimeInterval timestamp;
@property(nonatomic, retain) UIImage *image;

@end


@implementation CacheEntry
@synthesize refCount;
@synthesize timestamp;
@synthesize image;

-(void) dealloc
{
    self.image = nil;
    
    [super dealloc];
}
@end


@interface BasicMemoryCache()
{
    NSMutableDictionary *_map;
    NSInteger _size;
    NSRecursiveLock *_lock;
}

-(NSString *)findItemToInvalidate;
@end


@implementation BasicMemoryCache

-(void) internalInitWithSize :(NSInteger)size
{
    _size = DEFAULT_SIZE;
    _map = [[NSMutableDictionary alloc] initWithCapacity:_size];
    _lock = [[NSRecursiveLock alloc] init];
}


-(id) init
{
    if ((self = [super init]))
    {
        [self internalInitWithSize:DEFAULT_SIZE];
    }
    return self;
}


-(id) initWithSize:(NSInteger)size
{
    if ((self = [super init]))
    {
        [self internalInitWithSize:size];
    }
    return self;
}


+(id) imageCache
{
    return [[[BasicMemoryCache alloc] init] autorelease];
}


+(id) imageCacheWithSize:(NSInteger)size
{
    return [[[BasicMemoryCache alloc] initWithSize:size] autorelease];
}


-(void) dealloc
{
    sll_release(_lock);
    sll_release(_map);
    [super dealloc];
}


-(BOOL) exists:(NSString *)key
{
    BOOL result;
    
    [_lock lock];
    result = [_map objectForKey:key] != nil;
    [_lock unlock];
    
    return result;
}


-(void) invalidate:(NSString *)key
{
    [_lock lock];
    [_map removeObjectForKey:key];
    [_lock unlock];
}


-(void) storeImage:(id)data forKey :(NSString *)key
{
    [_lock lock];
    
    if (_map.count >= _size)
    // we need to remove an item out to prevent from increasing indefinitely.
    {
        [self invalidate:[self findItemToInvalidate]];
    }
    
    CacheEntry *entry = [[[CacheEntry alloc] init] autorelease];
    entry.refCount = 1;
    entry.timestamp = [[NSDate date] timeIntervalSince1970];
    entry.image = data;
    
    [_map setObject:entry forKey:key];
    [_lock unlock];
}


-(UIImage *)loadImage:(NSString *)key
{
    UIImage *image;
    
    [_lock lock];
    
    if (![self exists:key]) image = nil;
    
    CacheEntry *item = [_map objectForKey:key];
    item.refCount++;
    item.timestamp = [[NSDate date] timeIntervalSince1970];
    image = item.image;
    
    [_lock unlock];
    
    return image;
}


-(void) clear
{
    [_lock lock];
    [_map removeAllObjects];
    [_lock unlock];
}


//If the cache storage is full, return an item to be removed. 
//Default strategy: the oldest out: O(n)
-(NSString *)findItemToInvalidate
{
    CacheEntry *found = nil;
    NSString *foundKey = nil;
    for (NSString *key in _map.allKeys) 
    {
        CacheEntry *entry = [_map objectForKey:key];
        if (found == nil || entry.timestamp < found.timestamp)
        {
            found = entry;
            foundKey = key;
        }
        
    }
    
    return foundKey;
}

@end
