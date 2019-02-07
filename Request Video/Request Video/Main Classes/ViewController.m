//
//  ViewController.m
//  Request Video
//
//  Created by Golden Work on 7/14/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)Start:(id)sender{
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"user"] == nil){
        [self performSegueWithIdentifier:@"Login" sender:self];
    }else{
        [self performSegueWithIdentifier:@"Main" sender:self];
    }
}

@end
