//
//  SecondViewController.m
//  HTTPImageDemo
//
//  Created by Zonghai Li on 11/10/12.
//  Copyright (c) 2012 Shi Ling Long. All rights reserved.
//

#import "SecondViewController.h"

#import "HTTPImageManager.h"


@interface SecondViewController () <HTTPImageRequestDelegate>
{
        HTTPImageManager *_httpImageManager;
}
@end

@implementation SecondViewController
@synthesize imageView, progressView, spinnerView, urlLabel;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Progressive", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
        
        _httpImageManager = [[HTTPImageManager alloc] init];
    }
    return self;
}


-(void) dealloc
{
    self.imageView = nil;
    self.progressView = nil;
    self.spinnerView = nil;
    self.urlLabel = nil;
    
    [super dealloc];
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];

    urlLabel.text = @"http://www.skmecca.com/wp-content/uploads/2010/04/rainbow-ocean.jpg";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


-(IBAction)onStart:(id)sender
{
    HTTPImageRequest *request = [HTTPImageRequest requestWithURL:self.urlLabel.text andDelegate:self];
    [_httpImageManager loadImageIncrementally:request];
    self.imageView.image = nil;
    self.progressView.progress = 0.0;
    [self.spinnerView startAnimating];
}


-(void) request:(HTTPImageRequest *)request didFail:(NSError *)error
{
    [self.spinnerView stopAnimating];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}


-(void) request:(HTTPImageRequest *)request didLoadWithImage:(UIImage *)image
{
    self.imageView.image = image;
}


-(void) request:(HTTPImageRequest *)request didUpdatePartialImage:(UIImage *)partialImage
{
    self.imageView.image = partialImage;
}


-(void) request:(HTTPImageRequest *)request didUpdateProgress:(NSUInteger)loadSize ofTotalSize:(NSUInteger)totalSize
{
    if (loadSize == 0)
        [self.spinnerView stopAnimating];
    
    if(totalSize != 0)
        [self.progressView setProgress: (float)loadSize / totalSize animated:YES];
        
}

@end
