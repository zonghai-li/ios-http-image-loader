//
//  NSOperationStack.m
//
//  Version 1.0
//
//  Created by Nick Lockwood on 28/06/2012.
//  Copyright (c) 2012 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/NSOperationStack
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "NSOperationStack.h"

#import "SLLGlobal.h"


@interface NSOperationStack()
{
    NSRecursiveLock     *_lock;
}

- (void)setLIFODependendenciesForOperation:(NSOperation *)op;
@end


@implementation NSOperationStack


-(id) init
{
    if ((self = [super init]))
    {
        _lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}


-(void) dealloc
{
    sll_release(_lock);
    [super dealloc];
}


- (void)setLIFODependendenciesForOperation:(NSOperation *)op
{
    @try 
    {
        [_lock lock];
        
        //suspend queue
        BOOL wasSuspended = [self isSuspended];
        [self setSuspended:YES];

        NSArray *operationsSnapshot = [NSArray arrayWithArray:self.operations];
        NSInteger index = operationsSnapshot.count - 1;
        NSOperation *operation = nil;
        while (index >= 0 && (operation = [operationsSnapshot objectAtIndex:index--]).isExecuting) {};
        
        if(!operation.isExecuting)
            [operation addDependency:op];
        
        //resume queue
        [self setSuspended:wasSuspended];
    }
    @catch (NSException *e) 
    {
        // safeguard against any exceptions 
    }
    @finally 
    {
        [_lock unlock];
    }
}

- (void)addOperation:(NSOperation *)op
{
    [self setLIFODependendenciesForOperation:op];
    [super addOperation:op];
}

- (void)addOperations:(NSArray *)ops waitUntilFinished:(BOOL)wait
{
    for (NSOperation *op in ops)
    {
        [self setLIFODependendenciesForOperation:op];
    }
    [super addOperations:ops waitUntilFinished:wait];
}

- (void)addOperationWithBlock:(void (^)(void))block
{
    [self addOperation:[NSBlockOperation blockOperationWithBlock:block]];
}

@end
