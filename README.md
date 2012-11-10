This is a simple library that can address most of the requirement of asynchronously dowloading, caching and managing network image resources.

Loading an image is straightforward:

<code>
-(UIImage *) loadImage:(HTTPImageRequest *)request;
</code>


Interface
-------
To load an image, one will have to instantiate an HTTPImageRequest object, then use HTTPImageManager to issue the request.
HTTPImageRequest has the following variations:
* Set a target UIView for displaying the loaded image

<code>
+(id) requestWithURL:(NSString *)url forUIView: (UIView *)v;
</code>

 when the 'v' is a UIImageView, its 'image' property will be set to the loaded image;<br>
 when the 'v' is a UIButton, <code>[((UIButton *)v) setImage:image forState:UIControlStateNormal];</code> is called;<br>
 when the 'v' is of any other type, nothing is set.

* Or use this more generic form, to be free to deal with the loaded image in the HTTPImageCompletionBlock.

<code>
+(id) requestWithURL:(NSString *)url forUIView: (UIView *)v completionBlock: (HTTPImageCompletionBlock)block;
</code>



* Or set a delegate for being notified of the result

<code>
+(id) requestWithURL:(NSString *)url andDelegate:(id)delegate;            
</code>

Three-Level Caching Hierarchy
-------
[memory cache] -> [persistent storage cache] -> [network loader]

The memory cache is optional. To use too much memory cache may kill the system resource very fast. It is important to do so with a list view, though.

FIFO and LIFO Operation Queue
-------
LIFO is to improve responsiveness of a tableview, for example, when a user scrolls a list that loads a quite number of images sequentially.


Work with reused cells in UITableView
-------
When used in UITableViews that utilize techniques of reusing cell views, 

Progressive downloading
--------








