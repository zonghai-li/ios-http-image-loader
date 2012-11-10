//
//  TableViewController.m
//  HTTPImageDemo
//
//  Created by Zonghai Li on 11/10/12.
//  Copyright (c) 2012 Shi Ling Long. All rights reserved.
//

#import "TableViewController.h"

#import "HTTPImageManager.h"


@interface TableViewController ()
{
    NSArray *_urls;
    NSString *_pathThumbnailCache;

    HTTPImageManager *_httpImageManager;
    NSInteger counter;
}
@end

@implementation TableViewController


-(void) initPath
{	
    //Caches
	NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *pathCache = [array objectAtIndex:0];
    
    //Caches/Pictures
	_pathThumbnailCache = [pathCache stringByAppendingPathComponent:@"Pictures"];
    [self makeDirIfNotExists:_pathThumbnailCache];
    
}


-(BOOL)makeDirIfNotExists:(NSString *)dir
{
    BOOL isDirectory = FALSE;
    NSFileManager* fileMgr = [NSFileManager defaultManager];
	if (![fileMgr fileExistsAtPath:dir isDirectory:&isDirectory])
    {
		return [fileMgr createDirectoryAtPath:dir withIntermediateDirectories:NO attributes:nil error:nil];
	}
    return isDirectory;
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = NSLocalizedString(@"TableView", @"First");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
        
        [self initPath];
        
        _httpImageManager = [[HTTPImageManager alloc] initWithType:kHTTPImageQueueLIFO];
        _httpImageManager.memoryCache = [[[BasicMemoryCache alloc] initWithSize:64] autorelease];
        _httpImageManager.persistence = [[[FilePersistence alloc] initWithPath:_pathThumbnailCache] autorelease];
        
        _urls = [[NSArray arrayWithObjects:
              
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Brian%20Wilson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Daniel%20Johnston.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Syd%20Barrett.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Roky%20Erickson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Kurt%20Cobain.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Ray%20Davies.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Sinead%20O\'Connor.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Poly%20Styrene.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Brian%20Wilson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Daniel%20Johnston.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Syd%20Barrett.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Roky%20Erickson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Kurt%20Cobain.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Ray%20Davies.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Sinead%20O\'Connor.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Poly%20Styrene.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Brian%20Wilson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Daniel%20Johnston.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Syd%20Barrett.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Roky%20Erickson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Kurt%20Cobain.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Ray%20Davies.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Sinead%20O\'Connor.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Poly%20Styrene.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Brian%20Wilson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Daniel%20Johnston.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Syd%20Barrett.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Roky%20Erickson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Kurt%20Cobain.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Ray%20Davies.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Sinead%20O\'Connor.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Poly%20Styrene.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Brian%20Wilson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Daniel%20Johnston.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Syd%20Barrett.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Roky%20Erickson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Kurt%20Cobain.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Ray%20Davies.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Sinead%20O\'Connor.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Poly%20Styrene.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Brian%20Wilson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Daniel%20Johnston.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Syd%20Barrett.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Roky%20Erickson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Kurt%20Cobain.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Ray%20Davies.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Sinead%20O\'Connor.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Poly%20Styrene.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Brian%20Wilson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Daniel%20Johnston.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Syd%20Barrett.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Roky%20Erickson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Kurt%20Cobain.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Ray%20Davies.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Sinead%20O\'Connor.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Poly%20Styrene.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Brian%20Wilson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Daniel%20Johnston.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Syd%20Barrett.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Roky%20Erickson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Kurt%20Cobain.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Ray%20Davies.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Sinead%20O\'Connor.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/05/01/Poly%20Styrene.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Brian%20Wilson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Daniel%20Johnston.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Syd%20Barrett.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Roky%20Erickson.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Kurt%20Cobain.jpg",
                  @"http://www.pastemagazine.com/blogs/lists/2011/04/30/Ray%20Davies.jpg",
                  @"http://mat1.gtimg.com/www/mb/images/face/28.gif", 

                  nil] retain];
    }
    return self;
}


-(void) dealloc
{
    [_pathThumbnailCache release];
    [_httpImageManager release];
    [_urls release];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"total items = %d", _urls.count);
    return  _urls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) 
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.detailTextLabel.numberOfLines = 0;
        cell.imageView.tag = counter++;        
    }
    
    NSString *url = [_urls objectAtIndex:indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@"UIImageView: %d", cell.imageView.tag];
    cell.detailTextLabel.text = url;
    
    cell.imageView.image = [UIImage imageNamed:@"default_image"];
    [cell.imageView setImageWithUrl:url useHTTPImageManager:_httpImageManager];
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}
/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

@end
