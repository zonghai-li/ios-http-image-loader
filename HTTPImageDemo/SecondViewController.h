//
//  SecondViewController.h
//  HTTPImageDemo
//
//  Created by Zonghai Li on 11/10/12.
//  Copyright (c) 2012 Shi Ling Long. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SecondViewController : UIViewController

@property(nonatomic, retain) IBOutlet UIImageView *imageView;
@property(nonatomic, retain) IBOutlet UIProgressView *progressView;
@property(nonatomic, retain) IBOutlet UIActivityIndicatorView *spinnerView;
@property(nonatomic, retain) IBOutlet UILabel *urlLabel;


-(IBAction)onStart:(id)sender;
@end
