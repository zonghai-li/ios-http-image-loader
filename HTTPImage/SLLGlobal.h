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


#import <Foundation/Foundation.h>


////+++++++++++++++++++++++++++++++++++++++++++++++++++++
////    Memory Management 
////+++++++++++++++++++++++++++++++++++++++++++++++++++++
#if !__has_feature(objc_arc)

#define sll_release(__POINTER) { [__POINTER release]; }
#define sll_saferelease(__POINTER) { [__POINTER release]; __POINTER = nil; }
#define sll_autorelease(__POINTER) ( [__POINTER autorelease] );

#define sll_retain(__POINTER) ([__POINTER retain])

#define sll_weak

#else // -fobjc-arc

#define sll_release(__POINTER) 
#define sll_saferelease(__POINTER) { __POINTER = nil; }
#define sll_autorelease(__POINTER) (__POINTER)

#define sll_retain(__POINTER) (__POINTER)

#define sll_weak  __unsafe_unretained

#endif

// Release a CoreFoundation object safely.
#define sll_cf_saferelease(__REF) { if (nil != (__REF)) { CFRelease(__REF); __REF = nil; } }


////+++++++++++++++++++++++++++++++++++++++++++++++++++++
////    LOG 
////+++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifdef DEBUG
#define SLLog(xx, ...)  NSLog(@"%s(%d):\n" xx, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define SLLog(xx, ...)  ((void)0)
#endif // #ifdef DEBUG

#define SLLogRect(rect) \
SLLog("%s x=%.1f, y=%.1f, w=%.1f, h=%.1f", #rect, rect.origin.x, rect.origin.y, \
rect.size.width, rect.size.height)

#define SLLogPoint(pt) \
SLLog("%s x=%.1f, y=%.1f", #pt, pt.x, pt.y)

#define SLLogSize(size) \
SLLog("%s w=%.1f, h=%.1f", #size, size.width, size.height)

#define SLLogEdge(edges) \
SLLog("%s left=%.1f, right=%.1f, top=%.1f, bottom=%.1f", #edges, edges.left, edges.right, \
edges.top, edges.bottom)

#define SLLogColorHSV(_COLOR) \
SLLog("%s h=%f, s=%f, v=%f", #_COLOR, _COLOR.hue, _COLOR.saturation, _COLOR.value)

#define SLLogView(_VIEW) \
{ for (UIView* view = _VIEW; view; view = view.superview) { SLLog("%@", view); } }




